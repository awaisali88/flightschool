require File.dirname(__FILE__) + '/../test_helper'

class UserPhoneNumberTest < Test::Unit::TestCase
  fixtures :user_phone_numbers

  # Replace this with your real tests.
  def test_truth
    assert_kind_of UserPhoneNumber, user_phone_numbers(:first)
  end
end
