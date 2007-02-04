require File.dirname(__FILE__) + '/../test_helper'

class ExtraUserInfoTest < Test::Unit::TestCase
  fixtures :extra_user_infos

  # Replace this with your real tests.
  def test_truth
    assert_kind_of ExtraUserInfo, extra_user_infos(:first)
  end
end
