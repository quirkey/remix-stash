require 'socket'
require 'digest/md5'

class Stash::Cluster

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
    digest = Digest::MD5.digest(key)
    hash = digest.unpack("L")[0]
    count = @hosts.size
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

  def host_to_io(key, host, port)
    @@connections[key] ||= TCPSocket.new(host, port)
  end

end
