module Stash::Protocol
  extend self

  HEADER_FORMAT = "CCnCCnNNQ"

  # Magic codes
  REQUEST   = 0x80
  RESPONSE = 0x81

  # Command codes
  GET         = 0x00
  SET         = 0x01
  ADD         = 0x02
  REPLACE     = 0x03
  DELETE      = 0x04
  INCREMENT   = 0x05
  DECREMENT   = 0x06
  QUIT        = 0x07
  FLUSH       = 0x08
  GET_Q       = 0x09
  NO_OP       = 0x0A
  VERSION     = 0x0B
  GET_K       = 0x0C
  GET_K_Q     = 0x0D
  APPEND      = 0x0E
  PREPEND     = 0x0F
  STAT        = 0x10
  SET_Q       = 0x11
  ADD_Q       = 0x12
  REPLACE_Q   = 0x13
  DELETE_Q    = 0x14
  INCREMENT_Q = 0x15
  DECREMENT_Q = 0x16
  QUIT_Q      = 0x17
  FLUSH_Q     = 0x18
  APPEND_Q    = 0x19
  PREPEND_Q   = 0x20

  # Response codes
  NO_ERROR                  = 0x0000
  KEY_NOT_FOUND             = 0x0001
  KEY_EXISTS                = 0x0002
  VALUE_TOO_LARGE           = 0x0003
  INVALID_ARGUMENTS         = 0x0004
  ITEM_NOT_STORED           = 0x0005
  INCR_ON_NON_NUMERIC_VALUE = 0x0006
  UNKNOWN_COMMAND           = 0x0081
  OUT_OF_MEMORY             = 0x0082

  # Extras
  COUNTER_FAULT_EXPIRATION = 0xFFFFFFFF

  ADD_PACKET = HEADER_FORMAT + 'NNa*a*'
  def add(io, key, data, ttl = 0)
    header = [REQUEST, ADD, key.size, 8, 0, 0, data.size + key.size + 8, 0, 0, 0, ttl, key, data].pack(ADD_PACKET)
    io.write(header)
    resp = read_resp(io)
    resp[:status] == NO_ERROR
  end

  DECR_PACKET = HEADER_FORMAT + 'NNQNa*'
  def decr(io, key, step)
    low, high = split64(step)
    header = [REQUEST, DECREMENT, key.size, 20, 0, 0, key.size + 20, 0, 0, high, low, 0, COUNTER_FAULT_EXPIRATION, key].pack(DECR_PACKET)
    io.write(header)
    resp = read_resp(io)
    if resp[:status] == NO_ERROR
      parse_counter(resp[:body])
    end
  end

  DELETE_PACKET = HEADER_FORMAT + 'a*'
  def delete(io, key, ttl = 0)
    header = [REQUEST, DELETE, key.size, 0, 0, 0, key.size, 0, 0, key].pack(DELETE_PACKET)
    io.write(header)
    resp = read_resp(io)
    resp[:status] == NO_ERROR
  end

  FLUSH_PACKET = HEADER_FORMAT + 'N'
  def flush(io)
    header = [REQUEST, FLUSH, 0, 4, 0, 0, 4, 0, 0, 0].pack(FLUSH_PACKET)
    io.write(header)
    resp = read_resp(io)
    resp[:status] == NO_ERROR
  end

  GET_PACKET = HEADER_FORMAT + 'a*'
  def get(io, key)
    header = [REQUEST, GET, key.size, 0, 0, 0, key.size, 0, 0, key].pack(GET_PACKET)
    io.write(header)
    resp = read_resp(io)
    resp[:status] == NO_ERROR ? parse_get(resp[:body])[:value] : nil
  end

  def get_value(io, key)
    load_ruby_value(get(io, key))
  end

  INCR_PACKET = HEADER_FORMAT + 'NNQNa*'
  def incr(io, key, step)
    low, high = split64(step)
    header = [REQUEST, INCREMENT, key.size, 20, 0, 0, key.size + 20, 0, 0, high, low, 0, COUNTER_FAULT_EXPIRATION, key].pack(INCR_PACKET)
    io.write(header)
    resp = read_resp(io)
    if resp[:status] == NO_ERROR
      parse_counter(resp[:body])
    end
  end

  SET_PACKET = HEADER_FORMAT + 'NNa*a*'
  def set(io, key, data, ttl = 0)
    header = [REQUEST, SET, key.size, 8, 0, 0, data.size + key.size + 8, 0, 0, 0, ttl, key, data].pack(SET_PACKET)
    io << header
    resp = read_resp(io)
    resp[:status] == NO_ERROR
  end

  def set_value(io, key, value, ttl = 0)
    set(io, key, Marshal.dump(value), ttl)
  end

private

  def load_ruby_value(data)
    return unless data
    # TODO: Catch errors and try to fix them
    Marshal.load(data)
  end

  def parse_get(body)
    extra, value = body.unpack('Na*')
    {:extra => extra, :value => value}
  end

  def parse_counter(body)
    a, b = body.unpack('NN')
    b | (a << 32)
  end

  def read_resp(io)
    magic, opcode, key_length,
    extra, type, status,
    body_length, opaque, cas = *io.read(24).unpack(HEADER_FORMAT)
    resp = { :magic => magic, :opcode => opcode, :key_length => key_length,
      :extra => extra, :type => type, :status => status,
      :body_length => body_length, :opaque => opaque, :cas => cas }
    resp[:body] = io.read(body_length) if body_length > 0
    resp
  end

  def split64(n)
    [0xFFFFFFFF & n, n >> 32]
  end

end
