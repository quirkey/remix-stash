require 'benchmark'
require File.dirname(__FILE__) + '/../harness'
require File.dirname(__FILE__) + '/../harness_cache'

LARGE_NUMBER = 20_000

Benchmark.bm do |b|
  b.report('get/set stash') do
    LARGE_NUMBER.times {|n|
      stash[:abcxyz123] = n
      stash[:abcxyz123]
    }
  end
  b.report('get/set cache') do
    LARGE_NUMBER.times {|n|
      Cache.set('abcxyz123', n)
      Cache.get('abcxyz123')
    }
  end
end
