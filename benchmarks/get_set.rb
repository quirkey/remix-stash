require 'benchmark'
require File.dirname(__FILE__) + '/../harness'

LARGE_NUMBER = 20_000

Benchmark.bmbm do |b|
  b.report('get/set remix-stash') do
    LARGE_NUMBER.times {|n|
      stash[:abcxyz123] = n
      stash[:abcxyz123]
    }
  end
  b.report('get/set remix-stash named') do
    LARGE_NUMBER.times {|n|
      stash(:stuff)[:abcxyz123] = n
      stash(:stuff)[:abcxyz123]
    }
  end
  if defined?(CCache)
    b.report('get/set memcached') do
      LARGE_NUMBER.times {|n|
        CCache.set('abcxyz123', n)
        CCache.get('abcxyz123')
      }
    end
  end
  if defined?(RCache)
    b.report('get/set memcache-client') do
      LARGE_NUMBER.times {|n|
        RCache.set('abcxyz123', n)
        RCache.get('abcxyz123')
      }
    end
  end
end
