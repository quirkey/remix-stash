require File.dirname(__FILE__) + '/spec'

class AutoDetectionSpec < Spec

  context 'Rails' do

    should 'link the logger object' do
      assert_equal Rails.logger, stash.default[:logger]
    end

    should 'link cycle_action to an after filter' do
      assert ActionController::Base.after_filters.include?(:cycle_action_vectors)
    end

  end

  context 'environment variables' do

    should 'pick up cluster configuration from the environment' do
      assert_equal :environment, stash.default[:cluster]
    end

    should 'pick up namespace form the environment' do
      assert_equal 'spec', stash.default[:namespace]
    end

  end

end
