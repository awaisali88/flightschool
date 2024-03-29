module LoginEngine
  module AuthenticatedSystem
    
    protected

    # overwrite this if you want to restrict access to only a few actions
    # or if you want to check if the user has the correct rights  
    # example:
    #
    #  # only allow nonbobs
    #  def authorize?(user)
    #    user.login != "bob"
    #  end
    def authorize?(user)
       true
    end
  
    # overwrite this method if you only want to protect certain actions of the controller
    # example:
    # 
    #  # don't protect the login and the about method
    #  def protect?(action)
    #    if ['action', 'about'].include?(action)
    #       return false
    #    else
    #       return true
    #    end
    #  end
    def protect?(action)
      true
    end
   
    # login_required filter. add 
    #
    #   before_filter :login_required
    #
    # if the controller should be under any rights management. 
    # for finer access control you can overwrite
    #   
    #   def authorize?(user)
    # 
    def login_required
      if not protect?(action_name)
        return true  
      end

      if user? and authorize?(session[:user])
        return true
      end

      # store current location so that we can 
      # come back after the user logged in
      store_location
  
      # call overwriteable reaction to unauthorized access
      access_denied
      return false 
    end

    # overwrite if you want to have special behavior in case the user is not authorized
    # to access the current operation. 
    # the default action is to redirect to the login screen
    # example use :
    # a popup window might just close itself for instance
    def access_denied
      flash[:warning] = 'Please Login'
      redirect_to '/'
    end  
  
    # store current uri in  the session.
    # we can return to this location by calling return_location
    def store_location
      session['return-to'] = request.request_uri
    end

    # move to the last store_location call or to the passed default one
    def redirect_to_stored_or_default(default)
      if session['return-to'].nil?
        redirect_to default
      else
        redirect_to_url session['return-to']
        session['return-to'] = nil
      end
    end

    def redirect_back_or_default(default)
      if request.env["HTTP_REFERER"].nil?
        redirect_to default
      else
        redirect_to(request.env["HTTP_REFERER"]) # same as redirect_to :back
      end
    end

    def user?
      # First, is the user already authenticated?
      return true if not session[:user].nil?

      # If not, is the user being authenticated by a token?
      id = params[:user_id]
      key = params[:key]
      if id and key
        session[:user] = User.authenticate_by_token(id, key)
        return true if not session[:user].nil?
      end

      # Everything failed
      return false
    end
  
    # Returns the current user from the session, if any exists
    def current_user
#      session[:user].reload
      session[:user]
    end
  end
end  