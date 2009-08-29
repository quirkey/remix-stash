require File.dirname(__FILE__) + '/../harness'

p stash.gate(:x) {p :miss}
p :set_x
stash[:x] = true
p stash.gate(:x) {p :miss}
