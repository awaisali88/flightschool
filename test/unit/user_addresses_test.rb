require File.dirname(__FILE__) + '/../test_helper'

class UserAddressesTest < Test::Unit::TestCase
  fixtures :user_addresses

  # Replace this with your real tests.
  def test_truth
    assert_kind_of UserAddresses, user_addresses(:first)
  end
end
