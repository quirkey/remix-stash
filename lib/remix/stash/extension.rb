module Stash::Extension
  extend self

  def stash(name = :root)
    Stash.new(name)
  end

end
