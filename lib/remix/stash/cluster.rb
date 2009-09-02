require 'socket'
require 'digest/md5'

class Stash::Cluster
  include Socket::Constants

  @@connections = {}

  attr_reader :hosts

  def initialize(hosts)
    @hosts = hosts.map {|x|
      host, port = x.split(':')
      [x, host, (port || 11211).to_i]
    }.sort_by {|(_,h,p)| [h,p]}
  end

  def each
    @hosts.each do |h|
      yield(host_to_io(*h))
    end
  end

  # Note: Later, I'd like to support richer cluster definitions.
  # This should do the trick for now... and it's fast.
  def select(key)
    count = @hosts.size
    hash = nil
    if count > 1
      digest = Digest::MD5.digest(key)
      hash = digest.unpack("L")[0]
    else
      hash = 0
    end
    count.times do |try|
      begin
        break yield(host_to_io(*@hosts[(hash + try) % count]))
      rescue Stash::ProtocolError
        next
      end
      raise Stash::ClusterError,
        "Unable to find suitable host to communicate with for #{key.inspect} (MD5-32=#{hash})"
    end
  end

private

  if RUBY_PLATFORM =~ /java/

    def connect(host, port)
      # We currently don't support timeouts in JRuby since the socket API is
      # incomplete.
      TCPSocket.new(host, port)
    end

  else

    def connect(host, port)
      address = Socket.getaddrinfo(host, nil).first
      socket = Socket.new(Socket.const_get(address[0]), SOCK_STREAM, 0)
      timeout = [2,0].pack('l_2') # 2 seconds
      socket.setsockopt(SOL_SOCKET, SO_SNDTIMEO, timeout)
      socket.setsockopt(SOL_SOCKET, SO_RCVTIMEO, timeout)
      socket.connect(Socket.pack_sockaddr_in(port, address[3]))
      socket
    end

  end

  def host_to_io(key, host, port)
    @@connections[key] ||= connect(host, port)
  end

end
