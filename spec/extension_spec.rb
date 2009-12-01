require File.dirname(__FILE__) + '/spec'

class ExtensionSpec < Spec

  context 'Remix#stash' do

    should 'return a stash object with the correct name' do
      s = Remix.stash(:a)
      assert_instance_of Stash, s
      assert_equal :a, s.name
    end

    should 'return the same object when given the same name' do
      assert_equal Remix.stash(:b), Remix.stash(:b)
      assert_not_equal Remix.stash(:a), Remix.stash(:b)
    end

    should 'allow access to a default root stash' do
      assert_equal Remix.stash, Remix.stash(:root)
      assert_equal :root, Remix.stash.name
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
