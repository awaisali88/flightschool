require File.dirname(__FILE__) + '/../test_helper'
require 'reservation_rules_controller'

# Re-raise errors caught by the controller.
class ReservationRulesController; def rescue_action(e) raise e end; end

class ReservationRulesControllerTest < Test::Unit::TestCase
  fixtures :reservation_rules

  def setup
    @controller = ReservationRulesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:reservation_rules)
  end

  def test_show
    get :show, :id => 1

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:reservation_rule)
    assert assigns(:reservation_rule).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:reservation_rule)
  end

  def test_create
    num_reservation_rules = ReservationRule.count

    post :create, :reservation_rule => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_reservation_rules + 1, ReservationRule.count
  end

  def test_edit
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:reservation_rule)
    assert assigns(:reservation_rule).valid?
  end

  def test_update
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => 1
  end

  def test_destroy
    assert_not_nil ReservationRule.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      ReservationRule.find(1)
    }
  end
end
