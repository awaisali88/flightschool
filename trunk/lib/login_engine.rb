require 'login_engine/authenticated_user'
require 'login_engine/authenticated_system'

module LoginEngine
 include AuthenticatedSystem # re-include the helper module

  @configuration = {}
  
  def self.config k,v=nil
    if v.nil?
      return @configuration[k]
    else
      @configuration[k]=v
    end
  end


  #--
  # Define the configuration values. config sets the value of the
  # constant ONLY if it has not already been set, i.e. by the user in
  # environment.rb
  #++

  # Source address for user emails
  config :email_from, 'noreply@yourflightschool.com'

  # Destination email for system errors
  config :admin_email, 'admin@yourflightschool.com'

  # Sent in emails to users 
  config :app_url, 'http://yourflightschool.com'

  config :salt, "super-salt"
 
  # Sent in emails to users
  config :app_name, 'Your Flight School'

  # Email charset
  config :mail_charset, 'utf-8'

  # Security token lifetime in hours
  config :security_token_life_hours, 24

  # Two column form input
  config :two_column_input, true

  # Add all changeable user fields to this array.
  # They will then be able to be edited from the edit action. You
  # should NOT include the email field in this array.
  config :changeable_fields, [ 'first_names', 'last_name' ]

  # Set to true to allow delayed deletes (i.e., delete of record
  # doesn't happen immediately after user selects delete account,
  # but rather after some expiration of time to allow this action
  # to be reverted).
  config :delayed_delete, false

  # Default is one week
  config :delayed_delete_days, 7
  
  # the table to store user information in
  if ActiveRecord::Base.pluralize_table_names
    config :user_table, "users"
  else
    config :user_table, "user"
  end

  # controls whether or not email is used
  config :use_email_notification, true

  # Controls whether accounts must be confirmed after signing up
  # ONLY if this and use_email_notification are both true
  config :confirm_account, true

end
