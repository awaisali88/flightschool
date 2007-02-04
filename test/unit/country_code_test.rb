require File.dirname(__FILE__) + '/../test_helper'

class CountryCodeTest < Test::Unit::TestCase
  fixtures :country_codes

  # Replace this with your real tests.
  def test_truth
    assert_kind_of CountryCode, country_codes(:first)
  end
end
