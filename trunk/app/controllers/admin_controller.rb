##############################################
#
# admin_controller.rb
# @authors levpopov@mit.edu bdglide@mit.edu
# Controllers for site-adminstrator related functionality
#
##############################################

class AdminController < ApplicationController

before_filter :login_required 
before_filter :force_single_column_layout


# page with links to manage aircrafts
def aircrafts
  return unless has_permission :admin
  @page_title = "Manage Aircrafts"
end

# allows administrator to log in as given user, with the ability to switch back
def login_as_user
  return unless has_permission :can_login_as_any_user
  session[:user] = User.find_by_id(params[:id])
  session[:logged_in_as_different_user] = true
  redirect_to :back
end

# switches admin back to own account
def logout_as_user
  session[:user] = User.find_by_id(session[:admin_user_id])
  session[:logged_in_as_different_user] = false
  redirect_to :controller=>'admin',:action=>'users'
end

# page with list of users and links to their profiles as well as links to various administration functions
def users
  return unless has_permission :admin
  @page_title = 'User Administration'
    
  @letter = params[:letter] || 'A'
  user_view_config
  
  @users = User.find :all,
    :conditions=>["substring(upper(last_name),1,1)=? "+
                  (session[:show_suspended]== 'true'? '' : 'and account_suspended=false ')+
                  (session[:filter_office]=='none' ? '' : "and office=#{session[:filter_office]}"),
                  @letter], 
    :order => 'last_name'
  more_users = User.find :all,
      :conditions=>["substring(upper(last_name),1,1)>? "+
                    (session[:show_suspended]=='true' ? '' : 'and account_suspended=false ')+
                    (session[:filter_office]=='none' ? '' : "and office=#{session[:filter_office]}"),
                    @letter], 
      :order => 'last_name',
      :limit => (30-@users.size)
  @users = @users.concat(more_users)
end

def recent_users
  return unless has_permission :admin
  @page_title = 'Recently Created Users'
  user_view_config
  @pages,@users = paginate :users,:conditions=>(session[:filter_office]=='none' ? nil : ['office=?',session[:filter_office]]),
                  :order=>'created_at desc',:per_page=>30
end 

def zero_activity_users
  return unless has_permission :admin
  @page_title = 'Users With No Recent Activity'
  if request.method == :post
      User.transaction do
        begin
          params[:suspended].split('/').map{|u| u.to_i }.each{|user|
              User.permanently_delete_user user
          }
          flash[:notice] = 'Suspended users deleted.'
        rescue
          flash[:warning] = 'There was a problem with user deletion'
        end
      end
  end
  @users = User.find_by_sql(<<-"SQL"
                              select users.* from users where 
                              (select count(*) from groups_users where user_id = users.id and approved=true limit 1)=0
                              and (select count(*) from reservations where created_by = users.id and 
                                  time_start>'#{(Time.now-3.month)}' limit 1)=0
                              order by created_at desc;
                              SQL
                            )
  @suspended = @users.map{|u| u.account_suspended ? u.id : nil}.compact.join('/')
  
end 

def unapproved_users
  return unless has_permission :admin
  @page_title = 'Users With Items Pending Approval'
  user_view_config
  @users = User.find_by_sql(<<-"SQL"
                              select users.* from users where 
                              #{session[:filter_office]=='none' ? '' : 'users.office='+session[:filter_office]+' and '}
                              ((select count(*) from groups_users where user_id = users.id and approved=false)>0 or
                              (select count(*) from user_certificates where user_id = users.id and approved=false)>0 or
                              users.birthdate_approved = false or
                              users.physical_approved = false or
                              users.biennial_approved = false or
                              users.us_citizen_approved = false) and
                              users.account_suspended = false
                              order by users.id desc
                              SQL
                            )   
end

def approve_user_items
  return unless has_permission :admin
  user = User.find_by_id params[:id]
  user.email_verified = true
  user.birthdate_approved = true
  user.physical_approved = true
  user.us_citizen_approved = true
  user.biennial_approved = true
  user.save 
  user.approve_all_groups
  user.unapproved_certificates.each{|cert|
    cert.approved = true
    cert.save
  }
  redirect_to :back
end


def create_user
  return unless has_permission :admin
  @page_title = 'Add New User'
  @user = User.new
  @groups = Group.find :all, :order=>'group_name desc'
  if request.method == :post
    @user.new_password = true
    params[:user][:email].downcase!
    @user.email_verified = true
    if @user.update_attributes(params[:user])
     @groups.each{|group|
        if params[:groups]!= nil and params[:groups]["#{group.id}"]!=nil
           @user.add_group group
        end  
      }
      @user.approve_all_groups
      redirect_to :controller=>'profile',:action=>'edit',:id=>@user.id
    else
      flash[:warning] = 'Error creating user'
    end
  end
end

# gives a page with forms to change a user's  email, name, and/or password
# when post, changes user's email and name to specified fields
def edit_user
  return unless has_permission :admin
  @page_title = 'Change Name/Email Address'
  @user = User.find(params[:id])
  case request.method
  when :post
    @user.first_names = params[:user][:first_names]
    @user.last_name = params[:user][:last_name]
    @user.email = params[:user][:email]
    if @user.save
      redirect_to :action => 'edit_user', :id => params[:id] 
      flash[:notice] = "User's info updated"
      return
    end
  end
end

# changes users password to given new password
def edit_password
  return unless has_permission :admin
  @user = User.find(params[:id])
  case request.method
  when :post
    @user.change_password(params[:user][:password],params[:user][:password_confirmation])
    if @user.save
      flash[:notice] = "User's password updated"
    end
  end
  redirect_to :action => 'edit_user' , :id => params[:id]
end

# bans a user whose id is passed in params[:user_id]
def suspend
  return unless has_permission :admin
  user = User.find_by_id(params[:id])
  user.account_suspended = true
  if not user.save
    flash[:warning] = "Error suspending user"
  end
  redirect_to :back
end

# unbans a user whose id is passed in params[:user_id]
def unsuspend
  return unless has_permission :admin
  user = User.find_by_id(params[:id])
  user.account_suspended = false
  if not user.save
    flash[:warning] = "Error unsuspending user"
  end
  redirect_to :back
end

def delete_user
  return unless has_permission :admin
  begin
    user = User.find_by_id params[:id]
    User.permanently_delete_user user.id
    flash[:notice] = 'User deleted.'
    redirect_to :action=>'users'
  rescue
    flash[:warning] = 'User deletion failed.'
    redirect_to :back
  end
  
end

# Find Users page
def find
  return unless has_permission :admin
  @page_title = 'Find Users'
	if request.method == :post and params[:user_name].strip!=""
  	@users = User.find( :all ,:order=>"(LOWER(first_names) || ' ' || LOWER(last_name))",
                    	:conditions=>["(LOWER(first_names) || ' ' || LOWER(last_name)) like ?",
                    	              '%'+params[:user_name].downcase+'%'])
	end
end


def query

end

private

def user_view_config
  session[:show_suspended] ||= 'true'
  session[:show_suspended] = params[:show_suspended] unless params[:show_suspended].nil?
  session[:filter_office] ||= 'none'
  session[:filter_office] = params[:filter_office] unless params[:filter_office].nil?
end


end
