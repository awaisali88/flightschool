module PermissionsChecker

def no_access
  flash[:warning] = 'Sorry, this action is currently disabled for maintenance. The functionality will be restored as soon as possible.'
  redirect_to :back
  return false
end

def load_permissions
  if not session[:user].nil? then session[:user].reload end
  session[:permissions] ||= {} 
  session[:permissions].each_key{|k|
     session[:permissions][k] = false
  }
  
  if user?
      current_user.groups.each{|gr|
        session[:permissions][gr['group_name']] = true
      }
  end
  
end

def has_permission level
  if eval(level.to_s+'?')
    return true
  else
      flash[:warning] = 'Insufficient Permissions for this action'
      redirect_to :back
      return false
  end
end

def admin?
  return session[:permissions]['admin'] || false
end

def instructor?
  return session[:permissions]['instructor'] || false
end

def can_login_as_any_user?
  return admin?
end

def can_edit_any_user_info?
  return admin?
end

def can_view_any_user_info?
  return admin?
end

def can_approve_reservations?
  return (admin? or instructor?)
end

def can_edit_reservation_rules?
  return admin?
end

def can_manage_aircraft?
  return admin?
end

def can_do_billing?
  return admin?
end

def can_post_news?
  return admin?
end

def can_edit_site_content?
  return admin?
end

end