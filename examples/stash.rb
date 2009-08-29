require File.dirname(__FILE__) + '/../harness'

one = stash(:one)
two = stash(:two)

one[:x] = 10
two[:x] = 12

p one[:x]
p two[:x]

p :clearing
one.clear

p one[:x]
p two[:x]
