require File.dirname(__FILE__) + '/../harness'

# Get and set a simple key
stash.set('answer', 42)
p stash.get('answer')

# Alternate methods
stash[:answer] = :fortytwo
p stash[:answer]

# Composite keys
stash[1,2,3,4] = 5
p stash[1,2,3,4]
