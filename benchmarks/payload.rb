require 'benchmark'
require File.dirname(__FILE__) + '/../harness'

LARGE_NUMBER = 20_000

huge_value = 'a' * 100_000
large_value = 'b' * 20_000
med_value = 'c' * 2_000
small_value = 'd' * 100
tiny_value = 'e'

KEY = 'abc123xyz'

Benchmark.bmbm do |b|
  b.report('100k remix-stash') do
    LARGE_NUMBER.times {
      stash.write(KEY, huge_value)
      stash.read(KEY)
    }
  end
  if defined?(CCache)
    b.report('100k memcached') do
      LARGE_NUMBER.times {
        CCache.set(KEY, huge_value, 0, false)
        CCache.get(KEY, false)
      }
    end
  end
  if defined?(RCache)
    b.report('100k memcache-client') do
      LARGE_NUMBER.times {
        RCache.set(KEY, huge_value, 0, true)
        RCache.get(KEY, true)
      }
    end
  end
  b.report('20k remix-stash') do
    LARGE_NUMBER.times {
      stash.write(KEY, large_value)
      stash.read(KEY)
    }
  end
  if defined?(CCache)
    b.report('20k memcached') do
      LARGE_NUMBER.times {
        CCache.set(KEY, large_value, 0, false)
        CCache.get(KEY, false)
      }
    end
  end
  if defined?(RCache)
    b.report('20k memcache-client') do
      LARGE_NUMBER.times {
        RCache.set(KEY, large_value, 0, true)
        RCache.get(KEY, true)
      }
    end
  end
  b.report('2k remix-stash') do
    LARGE_NUMBER.times {
      stash.write(KEY, med_value)
      stash.read(KEY)
    }
  end
  if defined?(CCache)
    b.report('2k memcached') do
      LARGE_NUMBER.times {
        CCache.set(KEY, med_value, 0, false)
        CCache.get(KEY, false)
      }
    end
  end
  if defined?(RCache)
    b.report('2k memcache-client') do
      LARGE_NUMBER.times {
        RCache.set(KEY, med_value, 0, true)
        RCache.get(KEY, true)
      }
    end
  end
  b.report('100b remix-stash') do
    LARGE_NUMBER.times {
      stash.write(KEY, small_value)
      stash.read(KEY)
    }
  end
  if defined?(CCache)
    b.report('100b memcached') do
      LARGE_NUMBER.times {
        CCache.set(KEY, small_value, 0, false)
        CCache.get(KEY, false)
      }
    end
  end
  if defined?(RCache)
    b.report('100b memcache-client') do
      LARGE_NUMBER.times {
        RCache.set(KEY, small_value, 0, true)
        RCache.get(KEY, true)
      }
    end
  end
  b.report('1b remix-stash') do
    LARGE_NUMBER.times {
      stash.write(KEY, tiny_value)
      stash.read(KEY)
    }
  end
  if defined?(CCache)
    b.report('1b memcached') do
      LARGE_NUMBER.times {
        CCache.set(KEY, tiny_value, 0, false)
        CCache.get(KEY, false)
      }
    end
  end
  if defined?(RCache)
    b.report('1b memcache-client') do
      LARGE_NUMBER.times {
        RCache.set(KEY, tiny_value, 0, true)
        RCache.get(KEY, true)
      }
    end
  end
end
