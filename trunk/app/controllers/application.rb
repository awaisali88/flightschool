# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'login_engine'
#require 'crumbs'
require 'permissions_checker'
require 'multi_school'

require 'zlib' 
require 'stringio'

# Rails 1.2 broke how models dir is loaded, so we need to manually require all the model files in subdirs
require 'cms/document'
require 'cms/forum'
require 'cms/forum_post'
require 'cms/forum_topic'
require 'cms/image'
require 'cms/news_article'
require 'cms/root_document'
require 'cms/static_content'
require 'cms/uploaded_file'

require 'scheduling/maintenance_date'
require 'scheduling/reservation'
require 'scheduling/reservation_rule'
require 'scheduling/reservation_acceptance_rule'
require 'scheduling/reservation_approval_rule'
require 'scheduling/reservation_rules_exception'
require 'scheduling/schedule_mailer'
require 'scheduling/scheduling_access_rule'

require 'billing/billing_charge'
require 'billing/correction_record'
require 'billing/deposit_record'
require 'billing/fee_record'
require 'billing/flight_record'
require 'billing/ground_record'
require 'billing/supplies_record'


class ApplicationController < ActionController::Base
    include LoginEngine
    include PermissionsChecker
    include MultiSchool
    helper :user
    model :user
      
    before_filter :load_permissions
    before_filter :start_timer
    before_filter :populate_info_links
    after_filter :log_request

    protected 

    def populate_info_links
      @info_links = StaticContent.find(:first,:conditions =>["url_name='info_links'"]).body
    end
    
    #compresses the http output for performance
    def compress 
      accepts = request.env['HTTP_ACCEPT_ENCODING'] 
      return unless accepts && accepts =~ /(x-gzip|gzip)/ 

      encoding = $1 
      output = StringIO.new 

      def output.close # Zlib does a close. Bad Zlib... 
        rewind 
      end 

      gz = Zlib::GzipWriter.new(output) 
      gz.write(response.body) 
      gz.close 

      if output.length < response.body.length 
        response.body = output.string 
        response.headers['Content-encoding'] = encoding
      end 
    end 

#    before_filter :start_timer
#    after_filter :log_request, :except => [:image]
    
    def require_supported_browser
      if not browser_supported?
        flash[:warning] = "Sorry, but your browser is not supported by this application."+
        " Supported browsers include Internet Explorer 6.0+, Firefox 1.5+, Mozilla, and Camino. "+
        "We apologize for the inconvenience."
        redirect_to '/'
        return false
      end
    end
    
    def browser_supported?
      # Safari can't handle the scheduling page javascript... not yet
      return request.env['HTTP_USER_AGENT'].match('Safari').nil?
    end

    def require_schedule_access
      violated_rules = SchedulingAccessRule.violated_access_rules current_user
      if violated_rules.size>0
        flash[:warning] = 'You do not have access to the scheduling functionality for following reasons:<br/>'
        violated_rules.each{|r|
          flash[:warning] << '> '+r.description+'<br/>'
        }
        redirect_to :back
        return false
      end
    end
      
    def force_single_column_layout
      @layout_type = :single_column
    end
  
    # activity logging code adapted from sources by Zak Stone and Martin Glynn
    def start_timer
      @start_time = Time.now
    end

    def log_request 
      req  = Request.new
      req.request_params = params.to_s
      req.ip_address = request.remote_ip
      req.http_user_agent = request.env['HTTP_USER_AGENT']
      req.user_id = session[:user].nil? ? nil : session[:user].id
      req.http_referer = request.env['HTTP_REFERER']
      req.request_method = request.env['REQUEST_METHOD']
      req.request_uri = request.request_uri
      req.request_controller = request.symbolized_path_parameters[:controller]
      req.request_action = request.symbolized_path_parameters[:action]
      req.response_status = response.headers['Status']
      @end_time = Time.now
      req.elapsed_time = @end_time - @start_time
      req.save
    end
  
   protected
     def rescue_action_in_public(exception)
      case exception
      when ActiveRecord::RecordNotFound, ::ActionController::UnknownAction, ::ActionController::RoutingError
        render(:file => "#{RAILS_ROOT}/public/404.html",
               :status => "404 Not Found")
      else
        render(:file => "#{RAILS_ROOT}/public/500.html",
               :status => "500 Error")
      end
#      log_request
    end
  
end