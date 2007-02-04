require File.dirname(__FILE__) + '/../test_helper'
require 'aircraft_controller'

# Re-raise errors caught by the controller.
class AircraftController; def rescue_action(e) raise e end; end

class AircraftControllerTest < Test::Unit::TestCase
  fixtures :aircrafts

  def setup
    @controller = AircraftController.new
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

    assert_not_nil assigns(:aircrafts)
  end

  def test_show
    get :show, :id => 1

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:aircraft)
    assert assigns(:aircraft).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:aircraft)
  end

  def test_create
    num_aircrafts = Aircraft.count

    post :create, :aircraft => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_aircrafts + 1, Aircraft.count
  end

  def test_edit
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:aircraft)
    assert assigns(:aircraft).valid?
  end

  def test_update
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => 1
  end

  def test_destroy
    assert_not_nil Aircraft.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Aircraft.find(1)
    }
  end
end
