module Remix::Stash::Extension

  def stash(name = :root)
    Remix::Stash.new(name)
  end

end
