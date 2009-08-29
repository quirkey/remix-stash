require File.dirname(__FILE__) + '/../harness_cache'

# Simple get and set
Cache.set('answer', 42)
p Cache.get('answer')
