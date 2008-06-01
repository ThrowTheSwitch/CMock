require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"

class Thing
  def initialize foo, bar
    @foo = foo
    @bar = bar
  end

  def snafu
    return @foo.val + @bar.val
  end
end

class ThingTest < Test::Unit::TestCase
  def setup
    create_mocks :foo, :bar
    @thing = Thing.new(@foo, @bar)
  end

  def teardown
  end
  
  should "perform a stupid simple test" do
    @foo.expect.val.returns(1)
    @bar.expect.val.returns(2)
    
    assert_equal(3, @thing.snafu)
  end
end
