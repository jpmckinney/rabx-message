require 'spec_helper'

RSpec.describe RABX::Message do
  let :invalid_netstring do
    RABX::Message.new('R1:0,1:x')
  end

  let :invalid_rabx do
    RABX::Message.new('S1:0,I1:x')
  end

  let :n do
    RABX::Message.new('S1:0,N')
  end

  let :i do
    RABX::Message.new('S1:0,I2:34,')
  end
  let :invalid_i do
    RABX::Message.new('S1:0,I2:xy,')
  end

  let :r do
    RABX::Message.new('S1:0,R4:1.23,')
  end
  let :invalid_r do
    RABX::Message.new('S1:0,R4:abcd,')
  end

  let :t do
    RABX::Message.new('S1:0,T2:xy,')
  end

  let :b do
    RABX::Message.new('S1:0,B2:ab,')
  end

  let :l do
    RABX::Message.new('S1:0,L1:2,I2:34,T2:xy,')
  end
  let :invalid_l_size do
    RABX::Message.new('S1:0,L1:x,I2:34,T2:xy,')
  end
  let :missing_l_item do
    RABX::Message.new('S1:0,L1:2,I2:34,')
  end

  let :a do
    RABX::Message.new('S1:0,A1:2,I2:34,T2:xy,R4:1.23,B2:ab,')
  end
  let :invalid_a_size do
    RABX::Message.new('S1:0,A1:x,I2:34,T2:xy,R4:1.23,B2:ab,')
  end
  let :missing_a_item do
    RABX::Message.new('S1:0,A1:2,I2:34,T2:xy,')
  end
  let :missing_a_value do
    RABX::Message.new('S1:0,A1:2,I2:34,T2:xy,R4:1.23,')
  end

  let :invalid_type do
    RABX::Message.new('S1:0,U1:x,')
  end

  let :empty_message do
    'S1:0,'
  end
  let :empty do
    RABX::Message.new(empty_message)
  end

  let :request_message do
    'R1:0,6:method,L1:2,I2:34,T2:xy,'
  end
  let :request do
    RABX::Message.new(request_message)
  end

  let :success_message do
    'S1:0,A1:2,I2:34,T2:xy,R4:1.23,T2:ab,'
  end
  let :success do
    RABX::Message.new(success_message)
  end

  let :error_message do
    "E1:0,3:404,9:Not Found,N"
  end
  let :error do
    RABX::Message.new(error_message)
  end

  let :unknown_message do
    'U1:0,'
  end
  let :unknown do
    RABX::Message.new(unknown_message)
  end

  describe '.dump' do
    it 'should dump a RABX message' do
      {
        ['S'] => empty_message,
        ['R', 'method', [34, 'xy']] => request_message,
        ['S', {34 => 'xy', 1.23 => 'ab'}] => success_message,
        ['E', 404, 'Not Found'] => error_message,
        ['S', nil] => 'S1:0,N',
        ['S', true] => 'S1:0,I1:1,',
        ['S', false] => 'S1:0,I1:0,',
        ['S', 1] => 'S1:0,I1:1,',
        ['S', 1.1] => 'S1:0,R3:1.1,',
        ['S', 'x'] => 'S1:0,T1:x,',
        ['S', :x] => 'S1:0,T1:x,',
        ['S', []] => 'S1:0,L1:0,',
        ['S', {}] => 'S1:0,A1:0,',
      }.each do |args,string|
        expect(RABX::Message.dump(*args)).to eq(string)
      end
    end
  end

  describe '.load' do
    it 'should load a RABX request message' do
      message = RABX::Message.load(request_message)
      expect(message.method).to eq('method')
      expect(message.arguments).to eq([34, 'xy'])
    end

    it 'should load a RABX success message' do
      message = RABX::Message.load(success_message)
      expect(message.value).to eq({34 => 'xy', 1.23 => 'ab'})
    end

    it 'should load a RABX error message' do
      message = RABX::Message.load(error_message)
      expect(message.code).to eq('404')
      expect(message.text).to eq('Not Found')
      expect(message.extra).to eq(nil)
    end

    it 'should raise an error if type is unknown' do
      expect{RABX::Message.load(unknown_message)}.to raise_error(RABX::Message::ProtocolError, 'unknown RABX message type "U"')
    end
  end

  describe '#initialize' do
    it 'should initialize a RABX message' do
      expect{request}.to_not raise_error
    end

    it 'should make a copy of the string' do
      expect(request.instance_variable_get(:@s)).to eq('R1:0,6:method,L1:2,I2:34,T2:xy,')
      request_message.reverse!
      expect(request.instance_variable_get(:@s)).to eq('R1:0,6:method,L1:2,I2:34,T2:xy,')
    end

    it 'should raise an error if the string is empty' do
      expect{RABX::Message.new('')}.to raise_error(RABX::Message::ProtocolError, 'string is too short')
    end
  end

  describe '#to_s' do
    it 'should return the message' do
      expect(request.to_s).to eq(request_message)
    end
  end

  describe '#type' do
    it 'should return the message type' do
      expect(request.type).to eq('R')
      expect(success.type).to eq('S')
      expect(error.type).to eq('E')
    end
  end

  describe '#eof?' do
    it 'should return true only if the message has been read' do
      message = RABX::Message.new('S1:0,N')
      expect(message.eof?).to eq(false)
      expect(message.gets).to eq(nil)
      expect(message.eof?).to eq(true)
    end
  end

  describe '#getnetstring' do
    it 'should read a netstring' do
      expect(error.getnetstring).to eq('404')
      expect(error.getnetstring).to eq('Not Found')
    end

    it 'should return nil if at end of message' do
      expect(empty.getnetstring).to eq(nil)
      expect(empty.getnetstring).to eq(nil)
      expect(empty.getnetstring).to eq(nil)
    end

    it 'should raise an error if the netstring is invalid' do
      expect{invalid_netstring.getnetstring}.to raise_error(RABX::Message::ProtocolError)
    end
  end

  describe '#gets' do
    it 'should read a N message' do
      expect(n.gets).to eq(nil)
    end

    it 'should read a I message' do
      expect(i.gets).to eq(34)
    end
    it 'should raise an error if an integer is invalid' do
      expect{invalid_i.gets}.to raise_error(RABX::Message::ProtocolError, 'expected integer, got "xy" at position 8')
    end

    it 'should read a R message' do
      expect(r.gets).to eq(1.23)
    end
    it 'should raise an error if a float is invalid' do
      expect{invalid_r.gets}.to raise_error(RABX::Message::ProtocolError, 'expected float, got "abcd" at position 8')
    end

    it 'should read a T message' do
      expect(t.gets).to eq('xy')
    end

    it 'should read a B message' do
      expect(b.gets).to eq('ab')
    end

    it 'should read a L message' do
      expect(l.gets).to eq([34, 'xy'])
    end
    it 'should raise an error if a list size is invalid' do
      expect{invalid_l_size.gets}.to raise_error(RABX::Message::ProtocolError, 'expected integer, got "x" at position 8')
    end
    it 'should raise an error if a list item is missing' do
      expect{missing_l_item.gets}.to raise_error(RABX::Message::ProtocolError, 'expected 2 items, got 1 items at position 16')
    end

    it 'should read a A message' do
      expect(a.gets).to eq({34 => 'xy', 1.23 => 'ab'})
    end
    it 'should raise an error if a hash size is invalid' do
      expect{invalid_a_size.gets}.to raise_error(RABX::Message::ProtocolError, 'expected integer, got "x" at position 8')
    end
    it 'should raise an error if a hash item is missing' do
      expect{missing_a_item.gets}.to raise_error(RABX::Message::ProtocolError, 'expected 2 items, got 1 items at position 22')
    end
    it 'should raise an error if a hash value is missing' do
      expect{missing_a_value.gets}.to raise_error(RABX::Message::ProtocolError, 'expected value, got end-of-file at position 30')
    end

    it 'should raise an error if the type is invalid' do
      expect{invalid_type.gets}.to raise_error(RABX::Message::ProtocolError, 'bad type character "U" at position 6')
    end

    it 'should return nil if at end of message' do
      expect(empty.gets).to eq(nil)
      expect(empty.gets).to eq(nil)
      expect(empty.gets).to eq(nil)
    end

    it 'should raise an error if the netstring is invalid' do
      expect{invalid_rabx.gets}.to raise_error(RABX::Message::ProtocolError)
    end
  end
end
