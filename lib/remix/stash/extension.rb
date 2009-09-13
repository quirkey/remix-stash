module Remix::Stash::Extension
  extend self

  def stash(name = :root)
    Remix::Stash.new(name)
  end

end
