require File.dirname(__FILE__) + '/../test_helper'
require 'maintenance_controller'

# Re-raise errors caught by the controller.
class MaintenanceController; def rescue_action(e) raise e end; end

class MaintenanceControllerTest < Test::Unit::TestCase
  fixtures :maintenance_dates

  def setup
    @controller = MaintenanceController.new
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

    assert_not_nil assigns(:maintenance_dates)
  end

  def test_show
    get :show, :id => 1

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:maintenance_date)
    assert assigns(:maintenance_date).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:maintenance_date)
  end

  def test_create
    num_maintenance_dates = MaintenanceDate.count

    post :create, :maintenance_date => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_maintenance_dates + 1, MaintenanceDate.count
  end

  def test_edit
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:maintenance_date)
    assert assigns(:maintenance_date).valid?
  end

  def test_update
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => 1
  end

  def test_destroy
    assert_not_nil MaintenanceDate.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      MaintenanceDate.find(1)
    }
  end
end
