require 'socket'
require 'digest/md5'

class Remix::Stash::Cluster
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
      begin
        io = host_to_io(*h)
        break yield(io)
      rescue Errno::EPIPE, Errno::ECONNRESET, Remix::Stash::ProtocolError
        io.close
        retry
      rescue Errno::EAGAIN, Errno::ECONNREFUSED
        next
      end
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
        io = host_to_io(*@hosts[(hash + try) % count])
        return yield(io)
      rescue Errno::EPIPE, Errno::ECONNRESET, Remix::Stash::ProtocolError
        io.close
        retry
      rescue Errno::EAGAIN, Errno::ECONNREFUSED
        next
      end
    end
    raise Remix::Stash::ClusterError,
      "Unable to find suitable host to communicate with for #{key.inspect} (MD5-32=#{hash})"
  end

private

  def connect(host, port)
    socket = TCPSocket.new(host, port)
    set_timeout(socket, 2)
    socket
  end

  def host_to_io(key, host, port)
    socket = @@connections[key] ||= connect(host, port)
    return socket unless socket.closed?
    @@connections.delete(key)
    host_to_io(key, host, port)
  end

  def set_timeout(socket, seconds)
    timeout = [seconds, 0].pack('l_2') # 2 seconds
    socket.setsockopt(SOL_SOCKET, SO_SNDTIMEO, timeout)
    socket.setsockopt(SOL_SOCKET, SO_RCVTIMEO, timeout)
  end

end
