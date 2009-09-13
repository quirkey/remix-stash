require File.dirname(__FILE__) + '/spec'

class ExtensionSpec < Spec

  context '#stash' do

    should 'return a stash object with the correct name' do
      s = stash(:a)
      assert_instance_of Stash, s
      assert_equal :a, s.name
    end

    should 'return the same object when given the same name' do
      assert_equal stash(:b), stash(:b)
      assert_not_equal stash(:a), stash(:b)
    end

    should 'allow access to a default root stash' do
      assert_equal stash, stash(:root)
      assert_equal :root, stash.name
    end

  end

  context 'modules' do

    should 'be mixed into Object' do
      assert Object.respond_to?(:stash)
    end

    should 'be mixed into Remix' do
      assert Remix.respond_to?(:stash)
    end

  end

end
