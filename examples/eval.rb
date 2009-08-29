require File.dirname(__FILE__) + '/../harness'

stuff = stash(:stuff)

stuff.eval(:answer) {42}
p stuff.get(:answer)

stuff.eval(:asnwer) {fail 'Cache miss'}
