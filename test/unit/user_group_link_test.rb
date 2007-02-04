require File.dirname(__FILE__) + '/../test_helper'

class UserGroupLinkTest < Test::Unit::TestCase
  fixtures :user_group_links

  # Replace this with your real tests.
  def test_truth
    assert_kind_of UserGroupLink, user_group_links(:first)
  end
end
