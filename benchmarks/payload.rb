require 'benchmark'
require File.dirname(__FILE__) + '/../harness'
# require File.dirname(__FILE__) + '/../harness_cache'

LARGE_NUMBER = 20_000

large_value = 'a' * 100_000
med_value = 'b' * 2_000
small_value = 'c' * 100
tiny_value = 'd'

Benchmark.bm do |b|
  b.report('100k') do
    LARGE_NUMBER.times {
      stash.write('x', large_value)
      stash.read('x')
    }
  end
  b.report('2k') do
    LARGE_NUMBER.times {
      stash.write('x', med_value)
      stash.read('x')
    }
  end
  b.report('100 bytes') do
    LARGE_NUMBER.times {
      stash.write('x', small_value)
      stash.read('x')
    }
  end
  b.report('1 byte') do
    LARGE_NUMBER.times {
      stash.write('x', tiny_value)
      stash.read('x')
    }
  end
end
