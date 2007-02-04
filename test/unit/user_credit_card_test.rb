require File.dirname(__FILE__) + '/../test_helper'

class UserCreditCardTest < Test::Unit::TestCase
  fixtures :user_credit_cards

  # Replace this with your real tests.
  def test_truth
    assert_kind_of UserCreditCard, user_credit_cards(:first)
  end
end
