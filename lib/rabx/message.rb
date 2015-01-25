require 'netstring'

module RABX
  class Message
    class Error < StandardError; end
    class ProtocolError < Error; end
    class InterfaceError < Error; end

    # Dumps a RABX message.
    #
    # @param [String] type a message type
    # @param [Array] args message contents
    # @return [String] the REBX message
    def self.dump(type, *args)
      string = type + Netstring.dump('0')
      if type == 'R'
        string + Netstring.dump(args[0]) + _dump(args[1])
      elsif type == 'S'
        if args.size.zero?
          string
        else
          string + _dump(args[0])
        end
      elsif type == 'E'
        string + Netstring.dump(args[0]) + Netstring.dump(args[1]) + _dump(args[2])
      end
    end

    # Loads a RABX message.
    #
    # @param [String] s a RABX message
    # @return the contents of the message
    def self.load(s)
      message = new(s)
      if message.unknown?
        raise ProtocolError, %(unknown RABX message type "#{s[0]}")
      else
        version = message.getnetstring
        unless version == '0'
          raise ProtocolError, %(unknown protocol version "#{version}")
        end
        if message.success?
          message.gets
        elsif message.request?
          [message.getnetstring, message.gets]
        elsif message.error?
          code = message.getnetstring
          text = message.getnetstring
          text += message.gets.to_s unless message.eof?
          raise Error, "#{code}: #{text}"
        end
      end
    end

    # @param [String] s a RABX message
    def initialize(s)
      if s.empty?
        raise ProtocolError, 'string is too short'
      end
      @s = s.dup # string
      @p = 1 # pointer
      @size = s.size
    end

    # Returns the RABX message.
    #
    # @return [String] the RABX message
    def to_s
      @s
    end

    # Returns the message type.
    #
    # @return [String] the message type
    def type
      @s[0]
    end

    # Returns whether the message is a request message.
    #
    # @return [Boolean] whether the message is a request message
    def request?
      type == 'R'
    end

    # Returns whether the message is a success message.
    #
    # @return [Boolean] whether the message is a success message
    def success?
      type == 'S'
    end

    # Returns whether the message is a error message.
    #
    # @return [Boolean] whether the message is a error message
    def error?
      type == 'E'
    end

    # Returns whether the type of the message is unknown.
    #
    # @return [Boolean] whether the type of the message is unknown
    def unknown?
      !%w(R S E).include?(type)
    end

    # Returns whether the reader has reached the end-of-file.
    #
    # @return [Boolean] whether the reader has reached the end-of-file
    def eof?
      @p == @size
    end

    # Loads a netstring from the current position in the message.
    #
    # @return [Netstring,nil] a string, or nil if at end-of-file
    def getnetstring
      if eof?
        nil
      else
        string = Netstring.load(@s[@p..-1])
        @p += string.netstring.size
        string
      end
    rescue Netstring::Error => e
      raise ProtocolError, "#{e.message} in netstring starting at #{@p}"
    end

    # Loads a typed netstring from the current position in the message.
    #
    # @return the contents of the netstring, or nil if at end-of-file
    def gets
      if eof?
        nil
      else
        type = @s[@p]
        @p += 1

        if type == 'N'
          return nil
        end

        case type
        when 'I'
          value = getnetstring.to_s
          begin
            Integer(value)
          rescue ArgumentError
            raise ProtocolError, %(expected integer, got #{value.inspect} at position #{@p - value.size - 1})
          end
        when 'R'
          value = getnetstring.to_s
          begin
            Float(value)
          rescue ArgumentError
            raise ProtocolError, %(expected float, got #{value.inspect} at position #{@p - value.size - 1})
          end
        when 'T', 'B'
          getnetstring
        when 'L'
          value = getnetstring.to_s
          begin
            size = Integer(value)
          rescue ArgumentError
            raise ProtocolError, %(expected integer, got #{value.inspect} at position #{@p - value.size - 1})
          end
          array = []
          size.times do |n|
            if eof?
              raise ProtocolError, %(expected #{size} items, got #{n} items at position #{@p})
            end
            array << gets
          end
          array
        when 'A'
          value = getnetstring.to_s
          begin
            size = Integer(value)
          rescue ArgumentError
            raise ProtocolError, %(expected integer, got #{value.inspect} at position #{@p - value.size - 1})
          end
          hash = {}
          size.times do |n|
            if eof?
              raise ProtocolError, %(expected #{size} items, got #{n} items at position #{@p})
            end
            key = gets # test for repeated keys?
            if eof?
              raise ProtocolError, %(expected value, got end-of-file at position #{@p})
            end
            hash[key] = gets
          end
          hash
        else
          raise ProtocolError, %(bad type character "#{type}" at position #{@p})
        end
      end
    end

  private

    # RABX types:
    # * Null
    # * Integer
    # * Real
    # * Text
    # * Binary
    # * List
    # * Associative array
    def self._dump(args)
      case args
      when nil
        'N'
      when true
        'I' + Netstring.dump('1')
      when false
        'I' + Netstring.dump('0')
      when Integer
        'I' + Netstring.dump(args.to_s)
      when Float
        'R' + Netstring.dump(args.to_s)
      when String
        'T' + Netstring.dump(args)
      when Array
        'L' + Netstring.dump(args.size.to_s) + args.map{|arg| _dump(arg)}.join
      when Hash
        'A' + Netstring.dump(args.size.to_s) + args.map{|k,v| _dump(k) + _dump(v)}.join
      else
        raise InterfaceError, "can't pass #{args.class} over RABX"
      end
    end
  end
end
