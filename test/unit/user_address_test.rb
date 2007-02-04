require File.dirname(__FILE__) + '/../test_helper'

class UserAddressTest < Test::Unit::TestCase
  fixtures :user_addresses

  # Replace this with your real tests.
  def test_truth
    assert_kind_of UserAddress, user_addresses(:first)
  end
end
