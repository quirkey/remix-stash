module Stash::Protocol
  extend self

  HEADER_FORMAT = "CCnCCnNa4a8"

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

  def add(io, key, data)
    # Field        (offset) (value)
    # Magic        (0)    : 0x80
    # Opcode       (1)    : 0x02
    # Key length   (2,3)  : 0x0005
    # Extra length (4)    : 0x08
    # Data type    (5)    : 0x00
    # Reserved     (6,7)  : 0x0000
    # Total body   (8-11) : 0x00000012
    # Opaque       (12-15): 0x00000000
    # CAS          (16-23): 0x0000000000000000
    # Extras              :
    #   Flags      (24-27): 0xdeadbeef
    #   Expiry     (28-31): 0x00000e10
    # Key          (32-36): The textual string "Hello"
    # Value        (37-41): The textual string "World"
    header = [REQUEST, ADD, key.size, 8, 0, 0, data.size + key.size + 8, '', '', 0, 0, key, data].pack(HEADER_FORMAT + 'NNa*a*')
    io.write(header)
    resp = read_resp(io)
    resp[:status] == NO_ERROR
  end

  def decr(io, key, step)
    # Field        (offset) (value)
    # Magic        (0)    : 0x80
    # Opcode       (1)    : 0x06
    # Key length   (2,3)  : 0x0007
    # Extra length (4)    : 0x14
    # Data type    (5)    : 0x00
    # Reserved     (6,7)  : 0x0000
    # Total body   (8-11) : 0x0000001b
    # Opaque       (12-15): 0x00000000
    # CAS          (16-23): 0x0000000000000000
    # Extras              :
    #   delta      (24-31): 0x0000000000000001
    #   initial    (32-39): 0x0000000000000000
    #   exipration (40-43): 0x00000e10
    # Key                 : Textual string "counter"
    # Value               : None
    low, high = split64(step)
    header = [REQUEST, DECREMENT, key.size, 20, 0, 0, key.size + 20, '', '', high, low, 0, COUNTER_FAULT_EXPIRATION, key].pack(HEADER_FORMAT + 'NNQNa*')
    io.write(header)
    resp = read_resp(io)
    if resp[:status] == NO_ERROR
      parse_counter(resp[:body])
    end
  end

  def delete(io, key, ttl = 0)
    # Field        (offset) (value)
    # Magic        (0)    : 0x80
    # Opcode       (1)    : 0x04
    # Key length   (2,3)  : 0x0005
    # Extra length (4)    : 0x00
    # Data type    (5)    : 0x00
    # Reserved     (6,7)  : 0x0000
    # Total body   (8-11) : 0x00000005
    # Opaque       (12-15): 0x00000000
    # CAS          (16-23): 0x0000000000000000
    # Extras              : None
    # Key                 : The textual string "Hello"
    # Value               : None
    header = [REQUEST, DELETE, key.size, 0, 0, 0, key.size, '', '', key].pack(HEADER_FORMAT + 'a*')
    io.write(header)
    resp = read_resp(io)
    resp[:status] == NO_ERROR
  end

  def flush(io)
    # Field        (offset) (value)
    # Magic        (0)    : 0x80
    # Opcode       (1)    : 0x08
    # Key length   (2,3)  : 0x0000
    # Extra length (4)    : 0x04
    # Data type    (5)    : 0x00
    # Reserved     (6,7)  : 0x0000
    # Total body   (8-11) : 0x00000004
    # Opaque       (12-15): 0x00000000
    # CAS          (16-23): 0x0000000000000000
    # Extras              :
    #    Expiry    (24-27): 0x000e10
    header = [REQUEST, FLUSH, 0, 4, 0, 0, 4, '', '', 0].pack(HEADER_FORMAT + 'N')
    io.write(header)
    resp = read_resp(io)
    resp[:status] == NO_ERROR
  end

  def get(io, key)
    # Field        (offset) (value)
    # Magic        (0)    : 0x80
    # Opcode       (1)    : 0x00
    # Key length   (2,3)  : 0x0005
    # Extra length (4)    : 0x00
    # Data type    (5)    : 0x00
    # Reserved     (6,7)  : 0x0000
    # Total body   (8-11) : 0x00000005
    # Opaque       (12-15): 0x00000000
    # CAS          (16-23): 0x0000000000000000
    # Extras              : None
    # Key          (24-29): The textual string: "Hello"
    # Value               : None
    header = [REQUEST, GET, key.size, 0, 0, 0, key.size, '', '', key].pack(HEADER_FORMAT + 'a*')
    io.write(header)
    resp = read_resp(io)
    resp[:status] == NO_ERROR ? parse_get(resp[:body])[:value] : nil
  end

  def get_value(io, key)
    load_ruby_value(get(io, key))
  end

  def incr(io, key, step)
    # Field        (offset) (value)
    # Magic        (0)    : 0x80
    # Opcode       (1)    : 0x05
    # Key length   (2,3)  : 0x0007
    # Extra length (4)    : 0x14
    # Data type    (5)    : 0x00
    # Reserved     (6,7)  : 0x0000
    # Total body   (8-11) : 0x0000001b
    # Opaque       (12-15): 0x00000000
    # CAS          (16-23): 0x0000000000000000
    # Extras              :
    #   delta      (24-31): 0x0000000000000001
    #   initial    (32-39): 0x0000000000000000
    #   exipration (40-43): 0x00000e10
    # Key                 : Textual string "counter"
    # Value               : None
    low, high = split64(step)
    header = [REQUEST, INCREMENT, key.size, 20, 0, 0, key.size + 20, '', '', high, low, 0, COUNTER_FAULT_EXPIRATION, key].pack(HEADER_FORMAT + 'NNQNa*')
    io.write(header)
    resp = read_resp(io)
    if resp[:status] == NO_ERROR
      parse_counter(resp[:body])
    end
  end

  def set(io, key, data, ttl = 0)
    # Field        (offset) (value)
    # Magic        (0)    : 0x80
    # Opcode       (1)    : 0x01
    # Key length   (2,3)  : 0x0005
    # Extra length (4)    : 0x08
    # Data type    (5)    : 0x00
    # Reserved     (6,7)  : 0x0000
    # Total body   (8-11) : 0x00000012
    # Opaque       (12-15): 0x00000000
    # CAS          (16-23): 0x0000000000000000
    # Extras              :
    #   Flags      (24-27): 0xdeadbeef
    #   Expiry     (28-31): 0x00000e10
    # Key          (32-36): The textual string "Hello"
    # Value        (37-41): The textual string "World"
    header = [REQUEST, SET, key.size, 8, 0, 0, data.size + key.size + 8, '', '', 0, 0, key, data].pack(HEADER_FORMAT + 'NNa*a*')
    io.write(header)
    resp = read_resp(io)
    resp[:status] == NO_ERROR
  end

  def set_value(io, key, value, ttl = 0)
    set(io, key, Marshal.dump(value), ttl)
  end

  def method_missing(message, *a)
    fail [:NOT_IMPLEMENTED, self, message, *a].inspect
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
    resp[:body] = io.read(resp[:body_length]) if resp[:body_length] > 0
    resp
  end

  def split64(n)
    [0xFFFFFFFF & n, n >> 32]
  end

end
