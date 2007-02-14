#####################################################################################
#
# UserController implements user registration and editing functionality, providing
# methods to create new users, edit vital aspects of users and login/logout
#
# Authors:: Lev Popov levpopov@mit.edu, Brian Glidewell bdglide@mit.edu
# 
#####################################################################################

class UserController < ApplicationController
  model   :user
  before_filter :force_single_column_layout
  
public

  def alternate_login
    @page_title = 'Alternate Login'
  end
  
  # Override this function in your own application to define a custom home action.
  def home
    if user?
      @fullname = current_user.full_name
    else
      @fullname = "Not logged in..."
    end 
  end

  # The action used to log a user in. If the user was redirected to the login page
  # by the login_required method, they should be sent back to the page they were
  # trying to access. If not, they will be sent to "/user/home".
  def login
    case request.method
    when :post
      if params[:email] == nil || params[:email] == ""
        flash[:warning] = "Please enter your email"
        redirect_to '/'
      elsif params[:password] == nil || params[:password] == ""
        flash[:warning] = "Please enter your password"
        redirect_to '/'
      else
        params[:email].downcase!
        if session[:user] = User.authenticate(params[:email], params[:password])
          session[:user].last_login = DateTime.now()
          session[:user].save
          session[:logged_in_as_different_user] = false
          load_permissions
          if admin?
            session[:admin_user_id] = current_user.id
          end
          redirect_to '/'
        else
          user = User.find_by_email(params[:email])
          if not user.nil? and user.email_verified == false
            flash[:warning] = "Your account's email address has not been verified yet. Please check your email and click on a link in confirmation email sent to you."
          else
            flash[:warning] = 'Login unsuccessful. Please enter your email and password. <a href="/user/forgot_password">Forgot your password?</a>'
          end
          redirect_to '/'
        end
      end
    end
  end

  # Register as a new user. Upon successful registration, the user will be sent to
  # "/user/login" to enter their details.
  def signup    
    @page_title = 'Sign Up'
    return if generate_blank
    params[:user][:email].downcase!
    @user = User.new(params[:user])    
    if params[:account_type].nil?
      flash[:warning] = "Please select a user type (student/renter/instructor)."
      return
    end
    User.transaction(@user) do
        @user.new_password = true

        unless LoginEngine.config(:use_email_notification) and LoginEngine.config(:confirm_account)
          @user.email_verified = true
        end
      
        if @user.save	
          @group = Group.find_by_group_name(params[:account_type])  
          @user.add_group @group
          key = @user.generate_security_token
          url = url_for(:action => 'home', :user_id => @user.id, :key => key)
          UserNotify.deliver_signup(@user, params[:user][:password], url)

          flash[:notice] = 'Signup successful! Please check your email at '
          flash[:notice] << @user.email + ' and confirm your membership before using the system.'
          @session[:user] = nil
          redirect_to '/'
        end
      end
  end

  # logsout current user, removing id and permissions from session variables
  def logout
     session[:user] = nil
     session[:permissions] = {}
     session[:admin_user_id] = nil
     redirect_to '/'
  end

  # page with ability to change user's password
  # when new password is specified, also changes password
  def change_password
    return if generate_filled_in
    if do_change_password_for(@user)
      # since sometimes we're changing the password from within another action/template...
      #redirect_to :action => params[:back_to] if params[:back_to]
      redirect_back_or_default :action => 'change_password'
    end
  end

  
  protected
  
  # changes given user's password to new given password and emails notification to user
    def do_change_password_for(user)
#     begin
        User.transaction(user) do
          user.change_password(params[:user][:password], params[:user][:password_confirmation])
          if user.save
            if LoginEngine.config(:use_email_notification)
              UserNotify.deliver_change_password(user, params[:user][:password])
              flash[:notice] = "Updated password emailed to #{@user.email}"
            else
              flash[:notice] = "Password updated."
            end
            return true
          else
            flash[:warning] = 'There was a problem saving the password. Please retry.'
            return false
          end
        end
#      rescue
#        flash[:warning] = 'Password could not be changed at this time. Please retry.'
#      end
    end
    
  public

  # forwards to change_password if user signed in
  # if email disabled, sysadmin's email returned
  # if email valid, emails instructions for changing password
  def forgot_password
    @page_title = 'Forgotten Password'
    # Always redirect if logged in
    if user?
      flash[:message] = 'You are currently logged in. You may change your password now.'
      redirect_to :action => 'change_password'
      return
    end

    # Email disabled... we are unable to provide the password
    if !LoginEngine.config(:use_email_notification)
      flash[:message] = "Please contact the system admin at #{LoginEngine.config(:admin_email)} to retrieve your password."
      redirect_back_or_default :action => 'login'
      return
    end

    # Render on :get and render
    return if generate_blank
    params[:user][:email].downcase!
   
    # Handle the :post
    if params[:user][:email].empty?
      flash.now[:warning] = 'Please enter a valid email address.'
    elsif (user = User.find_by_email(params[:user][:email])).nil?
      flash.now[:warning] = "We could not find a user with the email address #{params[:user][:email]}"
    else
      begin
        User.transaction(user) do
          key = user.generate_security_token
          url = url_for(:action => 'change_password', :user_id => user.id, :key => key)
          UserNotify.deliver_forgot_password(user, url)
          flash[:notice] = "Instructions on resetting your password have been emailed to #{params[:user][:email]}"
        end  
        redirect_to :action => 'index', :controller => 'main'
      rescue
        flash.now[:warning] = "Your password could not be emailed to #{params[:user][:email]}"
      end
    end
  end
  
  protected
  
  # returns false if string is 'login', 'signup', or 'forgot_password, otherwise true
  def protect?(action)
    if ['login', 'signup', 'forgot_password'].include?(action)
      return false
    else
      return true
    end
  end

  # Generate a template user for certain actions on get
  def generate_blank
    case request.method
    when :get
      @user = User.new
      render
      return true
    end
    return false
  end

  # Generate a template user for certain actions on get
  def generate_filled_in
    get_user_to_act_on
    case request.method
    when :get
      render
      return true
    end
    return false
  end
  
  # returns the user object this method should act upon; only really
  # exists for other engines operating on top of this one to redefine...
  def get_user_to_act_on
    @user = session[:user]
  end
end
