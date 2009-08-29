require File.dirname(__FILE__) + '/../harness'

a = 0

stash(:x).scope {a}

stash(:x)[1] = 2

p stash(:x)[1]

a += 1

p stash(:x)[1]

a = 0

p stash(:x)[1]