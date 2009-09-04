require 'benchmark'
require File.dirname(__FILE__) + '/../harness'
require File.dirname(__FILE__) + '/../harness_cache'

LARGE_NUMBER = 20_000

large_value = 'a' * 100_000
med_value = 'b' * 2_000
small_value = 'c' * 100
tiny_value = 'd'

Benchmark.bm do |b|
  b.report('100k stash') do
    LARGE_NUMBER.times {
      stash.write('x', large_value)
      stash.read('x')
    }
  end
  b.report('100k cache') do
    LARGE_NUMBER.times {
      Cache.set('x', large_value, 0, true)
      Cache.get('x', true)
    }
  end
  b.report('2k stash') do
    LARGE_NUMBER.times {
      stash.write('x', med_value)
      stash.read('x')
    }
  end
  b.report('2k cache') do
    LARGE_NUMBER.times {
      Cache.set('x', med_value, 0, true)
      Cache.get('x', true)
    }
  end
  b.report('100b stash') do
    LARGE_NUMBER.times {
      stash.write('x', small_value)
      stash.read('x')
    }
  end
  b.report('100b cache') do
    LARGE_NUMBER.times {
      Cache.set('x', small_value, 0, true)
      Cache.get('x', true)
    }
  end
  b.report('1b stash') do
    LARGE_NUMBER.times {
      stash.write('x', tiny_value)
      stash.read('x')
    }
  end
  b.report('1b cache') do
    LARGE_NUMBER.times {
      Cache.set('x', tiny_value, 0, true)
      Cache.get('x', true)
    }
  end
end
