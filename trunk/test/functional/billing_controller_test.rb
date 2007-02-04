require File.dirname(__FILE__) + '/../test_helper'
require 'billing_controller'

# Re-raise errors caught by the controller.
class BillingController; def rescue_action(e) raise e end; end

class BillingControllerTest < Test::Unit::TestCase
  def setup
    @controller = BillingController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
