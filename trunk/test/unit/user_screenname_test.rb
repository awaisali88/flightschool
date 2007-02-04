require File.dirname(__FILE__) + '/../test_helper'

class UserScreennameTest < Test::Unit::TestCase
  fixtures :user_screennames

  # Replace this with your real tests.
  def test_truth
    assert_kind_of UserScreenname, user_screennames(:first)
  end
end
