Real docs coming soon! Check out the examples directory for more.

# Quick Specs

New API! I've rethought a lot of the API and this comes with a lot of new capabilities. More work is being done on making it as expressive as possible without terrible overhead.

It's fast (faster than memcache-client). It's simple (pure ruby and only a few hundred lines). It's tested (shoulda). Of course, because it's pure ruby it will run almost anywhere as well unlike many other clients.

It does require memcached 1.4+ but you should be running that anyway (if you aren't, upgrade already).

# TODO

* implement the rest of the memcached 1.4 binary API (replace, append, prepend)
* allow swappable cluster types for consistent hashing, ketama, etc...
* failsafe marshal load
* support non-marshal value dumps configured per stash
* support multi vector sets
* add block form
* quiet/multi command forms (will require a protocol refactoring most likely)
* server pings
* complete stats API
* incr/decr should take default value flags
* get/set add/replace read/write should allow a CAS flag to be passed
* accelerated binary API implementation with Ruby fallback
* redis support for vectors and/or value
* large key handling support
* UDP support (more experimentation on the tradeoffs)
* EventMachine integration (non-blocking?)
