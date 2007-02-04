require File.dirname(__FILE__) + '/../test_helper'

class UserCertificateTest < Test::Unit::TestCase
  fixtures :user_certificates

  # Replace this with your real tests.
  def test_truth
    assert_kind_of UserCertificate, user_certificates(:first)
  end
end
