require File.dirname(__FILE__) + '/../test_helper'
require 'stuff_controller'

# Re-raise errors caught by the controller.
class StuffController; def rescue_action(e) raise e end; end

class StuffControllerTest < Test::Unit::TestCase
  def setup
    @controller = StuffController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
