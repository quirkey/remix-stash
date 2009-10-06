module Remix::Stash::Runtime
  extend self

  @@logger = nil
  def logger
    @@logger
  end

  def logger=(log)
    @@logger = log
  end

end
