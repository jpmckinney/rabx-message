require 'spec_helper'

RSpec.describe RABX::Message do
  let :invalid_netstring do
    RABX::Message.new('R1:0,1:x')
  end

  let :invalid_rabx do
    RABX::Message.new('R1:0,I1:x')
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
    RABX::Message.new('R1:0,U1:x,')
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
    "E1:0,4:3002,31:Representative ID '0' not found,N"
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

  let :invalid_version do
    'S1:1,N'
  end

  describe '.dump' do
    it 'should dump a RABX message' do
      {
        ['S'] => empty_message,
        ['S', {34 => 'xy', 1.23 => 'ab'}] => success_message,
        ['R', 'method', [34, 'xy']] => request_message,
        ['E', '3002', "Representative ID '0' not found"] => error_message,
        ['S', nil] => 'S1:0,N',
        ['S', true] => 'S1:0,I1:1,',
        ['S', false] => 'S1:0,I1:0,',
        ['S', 1] => 'S1:0,I1:1,',
        ['S', 1.1] => 'S1:0,R3:1.1,',
        ['S', 'x'] => 'S1:0,T1:x,',
        ['S', []] => 'S1:0,L1:0,',
        ['S', {}] => 'S1:0,A1:0,',
      }.each do |args,string|
        expect(RABX::Message.dump(*args)).to eq(string)
      end
    end
  end

  describe '.load' do
    it 'should load a RABX success message' do
      expect(RABX::Message.load(success_message)).to eq({34 => 'xy', 1.23 => 'ab'})
    end

    it 'should load a RABX request message' do
      expect(RABX::Message.load(request_message)).to eq(['method', [34, 'xy']])
    end

    it 'should raise an error if type is unknown' do
      expect{RABX::Message.load(unknown_message)}.to raise_error(RABX::Message::ProtocolError, 'unknown RABX message type "U"')
    end

    it 'should raise an error if version is unrecognized' do
      expect{RABX::Message.load(invalid_version)}.to raise_error(RABX::Message::ProtocolError, 'unknown protocol version "1"')
    end

    it 'should raise an error if message is an error message' do
      expect{RABX::Message.load(error_message)}.to raise_error(RABX::Message::Error, "3002: Representative ID '0' not found")
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

  describe '#request?' do
    it 'should return true only if the message is a request message' do
      expect(request.request?).to eq(true)
      expect(success.request?).to eq(false)
      expect(error.request?).to eq(false)
      expect(unknown.request?).to eq(false)
    end
  end

  describe '#success?' do
    it 'should return true only if the message is a success message' do
      expect(request.success?).to eq(false)
      expect(success.success?).to eq(true)
      expect(error.success?).to eq(false)
      expect(unknown.success?).to eq(false)
    end
  end

  describe '#error?' do
    it 'should return true only if the message is an error message' do
      expect(request.error?).to eq(false)
      expect(success.error?).to eq(false)
      expect(error.error?).to eq(true)
      expect(unknown.error?).to eq(false)
    end
  end

  describe '#unknown?' do
    it 'should return true only if the message type is unknown' do
      expect(request.unknown?).to eq(false)
      expect(success.unknown?).to eq(false)
      expect(error.unknown?).to eq(false)
      expect(unknown.unknown?).to eq(true)
    end
  end

  describe '#eof?' do
    it 'should return true only if the message has been read' do
      expect(empty.eof?).to eq(false)
      expect(empty.getnetstring).to eq('0')
      expect(empty.eof?).to eq(true)
    end
  end

  describe '#getnetstring' do
    it 'should read a netstring' do
      expect(error.getnetstring).to eq('0')
      expect(error.getnetstring).to eq('3002')
      expect(error.getnetstring).to eq("Representative ID '0' not found")
    end

    it 'should return nil if at end of message' do
      expect(empty.getnetstring).to eq('0')
      expect(empty.getnetstring).to eq(nil)
      expect(empty.getnetstring).to eq(nil)
      expect(empty.getnetstring).to eq(nil)
    end

    it 'should raise an error if the netstring is invalid' do
      expect(invalid_netstring.getnetstring).to eq('0')
      expect{invalid_netstring.getnetstring}.to raise_error(RABX::Message::ProtocolError)
    end
  end

  describe '#gets' do
    it 'should read a N message' do
      expect(n.getnetstring).to eq('0')
      expect(n.gets).to eq(nil)
    end

    it 'should read a I message' do
      expect(i.getnetstring).to eq('0')
      expect(i.gets).to eq(34)
    end
    it 'should raise an error if an integer is invalid' do
      expect(invalid_i.getnetstring).to eq('0')
      expect{invalid_i.gets}.to raise_error(RABX::Message::ProtocolError, 'expected integer, got "xy" at position 8')
    end

    it 'should read a R message' do
      expect(r.getnetstring).to eq('0')
      expect(r.gets).to eq(1.23)
    end
    it 'should raise an error if a float is invalid' do
      expect(invalid_r.getnetstring).to eq('0')
      expect{invalid_r.gets}.to raise_error(RABX::Message::ProtocolError, 'expected float, got "abcd" at position 8')
    end

    it 'should read a T message' do
      expect(t.getnetstring).to eq('0')
      expect(t.gets).to eq('xy')
    end

    it 'should read a B message' do
      expect(b.getnetstring).to eq('0')
      expect(b.gets).to eq('ab')
    end

    it 'should read a L message' do
      expect(l.getnetstring).to eq('0')
      expect(l.gets).to eq([34, 'xy'])
    end
    it 'should raise an error if a list size is invalid' do
      expect(invalid_l_size.getnetstring).to eq('0')
      expect{invalid_l_size.gets}.to raise_error(RABX::Message::ProtocolError, 'expected integer, got "x" at position 8')
    end
    it 'should raise an error if a list item is missing' do
      expect(missing_l_item.getnetstring).to eq('0')
      expect{missing_l_item.gets}.to raise_error(RABX::Message::ProtocolError, 'expected 2 items, got 1 items at position 16')
    end

    it 'should read a A message' do
      expect(a.getnetstring).to eq('0')
      expect(a.gets).to eq({34 => 'xy', 1.23 => 'ab'})
    end
    it 'should raise an error if a hash size is invalid' do
      expect(invalid_a_size.getnetstring).to eq('0')
      expect{invalid_a_size.gets}.to raise_error(RABX::Message::ProtocolError, 'expected integer, got "x" at position 8')
    end
    it 'should raise an error if a hash item is missing' do
      expect(missing_a_item.getnetstring).to eq('0')
      expect{missing_a_item.gets}.to raise_error(RABX::Message::ProtocolError, 'expected 2 items, got 1 items at position 22')
    end
    it 'should raise an error if a hash value is missing' do
      expect(missing_a_value.getnetstring).to eq('0')
      expect{missing_a_value.gets}.to raise_error(RABX::Message::ProtocolError, 'expected value, got end-of-file at position 30')
    end

    it 'should raise an error if the type is invalid' do
      expect(invalid_type.getnetstring).to eq('0')
      expect{invalid_type.gets}.to raise_error(RABX::Message::ProtocolError, 'bad type character "U" at position 6')
    end

    it 'should return nil if at end of message' do
      expect(empty.getnetstring).to eq('0')
      expect(empty.gets).to eq(nil)
      expect(empty.gets).to eq(nil)
      expect(empty.gets).to eq(nil)
    end

    it 'should raise an error if the netstring is invalid' do
      expect(invalid_rabx.getnetstring).to eq('0')
      expect{invalid_rabx.gets}.to raise_error(RABX::Message::ProtocolError)
    end
  end
end
