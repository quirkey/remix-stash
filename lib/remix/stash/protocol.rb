module Remix::Stash::Protocol
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

  APPEND_PACKET = HEADER_FORMAT + 'a*a*'
  def append(io, key, data)
    header = [REQUEST, APPEND, key.size, 0, 0, 0, data.size + key.size, 0, 0, key, data].pack(APPEND_PACKET)
    io.write(header)
    resp = read_resp(io)
    resp[:status] == NO_ERROR
  end

  DECR_PACKET = HEADER_FORMAT + 'NNNNNa*'
  def decr(io, key, step, default = nil, ttl = nil)
    low, high = split64(step)
    if default
      default_low, default_high = split64(default)
      header = [REQUEST, DECREMENT, key.size, 20, 0, 0, key.size + 20, 0, 0, high, low, default_high, default_low, ttl, key].pack(DECR_PACKET)
    else
      header = [REQUEST, DECREMENT, key.size, 20, 0, 0, key.size + 20, 0, 0, high, low, 0, 0, COUNTER_FAULT_EXPIRATION, key].pack(DECR_PACKET)
    end
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
  GET_BODY = 4..-1
  def get(io, key)
    header = [REQUEST, GET, key.size, 0, 0, 0, key.size, 0, 0, key].pack(GET_PACKET)
    io.write(header)
    resp = read_resp(io)
    resp[:status] == NO_ERROR ? resp[:body][GET_BODY] : nil
  end

  INCR_PACKET = HEADER_FORMAT + 'NNNNNa*'
  def incr(io, key, step, default = nil, ttl = nil)
    low, high = split64(step)
    if default
      default_low, default_high = split64(default)
      header = [REQUEST, INCREMENT, key.size, 20, 0, 0, key.size + 20, 0, 0, high, low, default_high, default_low, ttl, key].pack(DECR_PACKET)
    else
      header = [REQUEST, INCREMENT, key.size, 20, 0, 0, key.size + 20, 0, 0, high, low, 0, 0, COUNTER_FAULT_EXPIRATION, key].pack(INCR_PACKET)
    end
    io.write(header)
    resp = read_resp(io)
    if resp[:status] == NO_ERROR
      parse_counter(resp[:body])
    end
  end

  PREPEND_PACKET = HEADER_FORMAT + 'a*a*'
  def prepend(io, key, data)
    header = [REQUEST, PREPEND, key.size, 0, 0, 0, data.size + key.size, 0, 0, key, data].pack(PREPEND_PACKET)
    io.write(header)
    resp = read_resp(io)
    resp[:status] == NO_ERROR
  end

  REPLACE_PACKET = HEADER_FORMAT + 'NNa*a*'
  def replace(io, key, data, ttl = 0)
    header = [REQUEST, REPLACE, key.size, 8, 0, 0, data.size + key.size + 8, 0, 0, 0, ttl, key, data].pack(REPLACE_PACKET)
    io.write(header)
    resp = read_resp(io)
    resp[:status] == NO_ERROR
  end

  SET_PACKET = HEADER_FORMAT + 'NNa*a*'
  def set(io, key, data, ttl = 0)
    header = [REQUEST, SET, key.size, 8, 0, 0, data.size + key.size + 8, 0, 0, 0, ttl, key, data].pack(SET_PACKET)
    io << header
    resp = read_resp(io)
    resp[:status] == NO_ERROR
  end

  STAT_PACKET = HEADER_FORMAT + 'a*'
  def stat(io, info = '')
    header = [REQUEST, STAT, info.size, 0, 0, 0, info.size, 0, 0, info].pack(STAT_PACKET)
    io.write(header)
    loop do
      stat = read_stat(io, info)
      break unless stat[:key]
      yield *stat.values_at(:key, :value)
    end
  end

private

  COUNTER_SPLIT = 'NN'
  def parse_counter(body)
    a, b = body.unpack(COUNTER_SPLIT)
    b | (a << 32)
  end

  RESP_HEADER = '@6nN'
  def read_resp(io)
    header = io.read(24)
    header or raise Remix::Stash::ProtocolError,
      "No data in response header"
    status, body_length = *header.unpack(RESP_HEADER)
    body_length.zero? ?
      {:status => status} :
      {:status => status, :body => io.read(body_length)}
  end

  STAT_HEADER = '@2n@6nN'
  def read_stat(io, info)
    header = io.read(24)
    header or raise Remix::Stash::ProtocolError,
    "No data in response header"
    key_length, status, body_length = *header.unpack(STAT_HEADER)
    stat = {:status => status}
    stat[:key] = io.read(key_length) if key_length > 0
    stat[:value] = io.read(body_length - key_length) if body_length - key_length > 0
    stat
  end

  def split64(n)
    [0xFFFFFFFF & n, n >> 32]
  end

end
