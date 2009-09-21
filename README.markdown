Real docs coming soon! Check out the examples directory for more.

# Quick Specs

New API! I've rethought a lot of the API and this comes with a lot of new capabilities. More work is being done on making it as expressive as possible without terrible overhead. This includes vectorized keys which allow emulation of partial cache clearing as well as nice shortcuts like eval and gate for expressions. Options, clusters, and implicit scope are easy to manage on a stash-by-stash basis. Keys are also easy to pass in as it will create composite keys from whatever you pass in (as long as it has to_s) so no more ugly string interpolation all over the place.

It's fast (faster than memcache-client). It's simple (pure ruby and only a few hundred lines). It's tested (shoulda). Of course, because it's pure ruby it will run almost anywhere as well unlike many other clients.

It does require memcached 1.4+ but you should be running that anyway (if you aren't, upgrade already).

Take a look and let me know what you think!

# TODO

* namespacing
* implement the rest of the memcached 1.4 binary API (replace, append, prepend)
* allow swappable cluster types for consistent hashing, ketama, etc...
* failsafe marshal load
* support non-marshal value dumps configured per stash
* support multi vector sets
* thread safe cluster
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
