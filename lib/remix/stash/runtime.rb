module Remix::Stash::Runtime
  extend self

  @@logger = nil
  def logger
    @@logger
  end

  def logger=(log)
    @@logger = log
  end

  @@ignore_cluster_errors = false
  def ignore_cluster_errors
    @@ignore_cluster_errors
  end

  def ignore_cluster_errors=(bool)
    @@ignore_cluster_errors = bool
  end

end
