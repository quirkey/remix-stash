Coming Soon!

# Quick Specs

It's fast (over 2x faster than memcache-client). It's simple (pure ruby and only a few hundred lines). It's tested (shoulda).

It does require memcached 1.4+ but you should be running that anyway (if you aren't, upgrade already).

# TODO

* optimize option merging with cache
* make clusters selectable per stash
* implement the rest of the memcached 1.4 binary API
* allow swappable cluster types for consistent hashing, ketama, etc...
* failsafe marshal load
* support non-marshal value dumps configured per stash
* support intersected stashes with joined vector sets
* add jruby specific cluster implementations to work around the lack socket timeouts
