require File.dirname(__FILE__) + '/../harness'

stuff = stash(:stuff)

stuff.eval(:ans) {42}
p stuff.get(:ans)

stuff.eval(:ans) {fail 'Cache miss'}
