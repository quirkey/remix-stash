# Quick & Dirty Specs

New API that doesn't actually suck! I've rethought a lot of the API and this comes with a lot of new capabilities. More work is being done on making it as expressive as possible without terrible overhead. This includes vectorized keys which allow emulation of partial cache clearing as well as nice shortcuts like eval and gate for expressions. Options, clusters, and implicit scope are easy to manage on a stash-by-stash basis. Keys are also easy to pass in as it will create composite keys from whatever you pass in (as long as it has to_s) so no more ugly string interpolation all over the place.

It's fast (faster than memcache-client). It's simple (pure ruby and only a few hundred lines). It's tested (shoulda). Of course, because it's pure ruby it will run almost anywhere as well unlike many other clients.

It does require memcached 1.4+ but you should be running that anyway (if you aren't, upgrade already).

Take a look at the examples and let me know what you think!

# Installation

Right now remix-stash is designed to be run as a gem. I've published it to both github and gemcutter (preferred). You can also safely use this as a rails plugin, just check out the source in your plugin directory and it will be automatically loaded.

## Install via GemCutter

    gem install remix-stash --source=http://gemcutter.org/

## Install via GitHub

    gem install binary42-remix-stash --source=http://gems.github.com/

# Specifications

This project is tested with shoulda (install via the thoughtbot-shoulda gem on github) and takes the philosophy that fewer moving parts is better. So to avoid complex runners just run `spec/spec.rb` or the spec you are interested in directly. In order for the specs to function, you should have memcached 1.4+ running locally on port 11211.

# Future Work

* implement the rest of the memcached 1.4 binary API (replace, append, prepend)
* allow swappable cluster types for consistent hashing, ketama, etc...
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
