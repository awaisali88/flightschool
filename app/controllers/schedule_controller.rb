##############################################################################
#
# Controller for all scheduling-related functionality, including creating
# browsing and editing reservations. All the reservations are stored in
# reservations table in the database, which is wrapped into Reservation 
# ActiveRecord class. 
#
# Authors:: Lev Popov levpopov@mit.edu
#
##############################################################################

class ScheduleController < ApplicationController

  before_filter :require_supported_browser, :except=>['quickpick','quickpick_update','reservation_summary']
  before_filter :require_schedule_access, :except=>['quickpick','quickpick_update','reservation_summary']

# # Serves one of two pages based on params[:reservation_id] 
# # If  params[:reservation_id] is present then a page with 
# # detailed information for the reservation with that id is rendered.
# # Otherwise, a paginated list of all user's (current_user or  user with id in params[:instructor_id])
# # reservations is presented
# def reservations
#    if params[:reservation_id].nil? #list all reservations for a user
#       @user_id =  params[:user].nil? ? current_user.id : params[:user]
#       if @user_id != current_user.id && !can_approve_reservations? then return end
#       if params[:showall]
#         @reservation_pages, @reservations = paginate :reservations, :conditions=>["created_by = ? and reservation_type='booking'",@user_id],:order=>'time_start desc', :per_page => 10
#       else
#         @reservations = Reservation.find(:all,:conditions=>["created_by = ? and reservation_type='booking' and status!='canceled' and time_end>?",@user_id,Time.new],:order=>'time_start desc')
#       end
#       @page_title = "Reservations for "+User.find_by_id(@user_id).full_name
#     else #show just one reservation for editing
#       @reservation = Reservation.find_by_id(params[:reservation_id])
#       if @reservation.instructor_id != current_user.id && @reservation.created_by != current_user.id &&  !can_approve_reservations?
#         render :partial => 'error', :layout=>'application'
#       else
#         @page_title = "Reservation #"+@reservation.id.to_s
#         render :partial => 'edit_reservation', :layout=>'application'
#       end
#     end
# end
# 
# # Shows a page for an instructor (current_user or user with id in params[:instructor_id]) \
# # with a paginated list of reservations that his students have created.
# # params[:showall] - show expired and canceled reservations along with current reservations
# def instructor_reservations
#   @instructor = params[:instructor_id].nil? ? current_user.id : params[:instructor_id]
#   if @instructor != current_user.id && !can_approve_reservations? then return end
#   @page_title = "Reservations for Instructor "+User.find_by_id( @instructor).full_name
#   if params[:showall]
#     @reservation_pages, @reservations = paginate :reservations, :conditions=>["instructor_id = ? and reservation_type='booking'",@instructor],:order=>'time_start desc', :per_page => 10
#   else
#     @reservations = Reservation.find(:all,:conditions=>["instructor_id = ? and reservation_type='booking' and status!='canceled' and time_end>?",@instructor,Time.new],:order=>'time_start desc')
#   end
# end

# sub-component rendered within news page (/index) that display summary of user's reservations (both for instructors and students)
def reservation_summary
  if SchedulingAccessRule.violated_access_rules(current_user).size > 0
    render :text=>''
    return
  end
  @user = current_user
  if instructor? 
    @reservations = Reservation.find(:all,:conditions=>["instructor_id = ? and reservation_type='booking' and status!='canceled' and time_end>?",@user.id,Time.new],:order=>'time_start desc')    
  else
    @reservations = Reservation.find(:all,:conditions=>["created_by = ? and reservation_type='booking' and status!='canceled' and time_end>?",@user.id,Time.new],:order=>'time_start desc')
  end
  render :partial => 'reservation_summary'
end

# Renders quick-scheduling interface (page component that fits on a sidebar and lets user
# create a simple reservation that doesnt span multiple days or require an aircraft in office 
# other than user's home office (current_user.default_office)
def quickpick
  if SchedulingAccessRule.violated_access_rules(current_user).size > 0
    render :text=>''
    return
  end
  
  @user = current_user  

  #check that there are instructors and aircraft to pick from:
  session[:scheduling] ||= {} 
  session[:scheduling][:aircraft_id] ||= Aircraft.find(:first).id

  # TODO: extract this code to Group class
  @instructors = Group.users_in_group('instructor')
  @tmp = []
  @instructors.each{|x|
    if x.office.to_s == @user.office.to_s then @tmp<<x end
  } 
  @instructors= @tmp #filtered list with local instructor only
  aircraft = Aircraft.find(:first)
  if aircraft == nil
    render :text => 'Service Unavailable'
    return
  end
  
  @reservation = Reservation.new
 #  session[:scheduling][:instructor_id] ||= @instructors.first.id
  
  if (@instructors.map{|user| user.id.to_i}).include? session[:scheduling][:instructor_id].to_i
    @reservation.instructor_id = session[:scheduling][:instructor_id]
  else
    @reservation.instructor_id = nil #@instructors.first.id
  end
  
  @instructor = User.find_by_id(@reservation.instructor_id)
  t = Time.new
  @reservation.time_start =  Time.local(t.year,t.month,t.day,7)
  @reservation.time_end =  Time.local(t.year,t.month,t.day,9)
  
  aircraft = Aircraft.find_by_id(session[:scheduling][:aircraft_id],:conditions => ['office=?',current_user.office]) || Aircraft.find(:first,:conditions => ['deleted = false and office=?',current_user.office])
  if aircraft.deleted then aircraft = Aircraft.find(:first,:conditions => ['deleted = false and office=?',current_user.office]) end
  @reservation.aircraft_id = aircraft.id
  @aircraft_type = aircraft.aircraft_type
  @aircrafts = Aircraft.find_all_by_aircraft_type(@aircraft_type, :conditions => ['deleted = false and office=?',current_user.office])
 
  from = @reservation.time_start.to_date.to_time
  to = (@reservation.time_start.to_date+1).to_time
  
  @instructor_reservations = Reservation.instructor_reservations @reservation.instructor_id,from,to
  
  @aircraft_reservations = {}
  @aircrafts.each{|aircraft|
         @aircraft_reservations[aircraft.id] = Reservation.aircraft_reservations aircraft.id,from,to
  }
  
  render :partial => 'quickpick_wrapper'
end

# quickpick_update responds to AJAX request sent from quick-scheduling interface 
# whenever user selects a new date, aircraft_type or instructor is selected.
# This method re-renders the quickscheduling interface, according to the newly
# selected values
def quickpick_update
  @reservation = Reservation.new(params[:reservation])  
  @instructors = Group.users_in_group('instructor')
  
 
  aircraft = Aircraft.find_by_id(@reservation.aircraft_id)
  if aircraft.aircraft_type.to_i != params[:reservation_aircraft_type].to_i
     @reservation.aircraft_id = Aircraft.find(:first, :conditions => ['aircraft_type = ? and deleted = false and office=?',params[:reservation_aircraft_type],current_user.office]).id
  end

  session[:scheduling][:aircraft_id] = @reservation.aircraft_id
  session[:scheduling][:instructor_id] = params[:instructor_id]
  
  @instructor = User.find_by_id(@reservation.instructor_id)
  
  @aircraft_type = params[:reservation_aircraft_type].to_i
  @aircrafts = Aircraft.find_all_by_aircraft_type(@aircraft_type,:conditions => ['deleted = false and office=?',current_user.office])
 
  from = @reservation.time_start.to_date.to_time
  to = (@reservation.time_start.to_date+1).to_time

#  to = Time.local(date.year,date.month,date.day,0)

  @instructor_reservations = Reservation.instructor_reservations @reservation.instructor_id,from,to
  
  @aircraft_reservations = {}
  @aircrafts.each{|aircraft|
         @aircraft_reservations[aircraft.id] = Reservation.aircraft_reservations aircraft.id,from,to
  }
  
  render :partial => 'quickpick'
end

# # Creates a new reservation with properties passed to in params[:reservation].
# # All of the appropriate reservation rules are checked and an appropriate confirmation
# # page is displayed to the user.
# def new_reservation
#   @reservation = Reservation.new(params[:reservation])
#   if  not params[:date].nil? #quickpick reservation
#     # date = params[:date].to_date
#     #  @reservation.year = date.year
#     #  @reservation.month = date.month
#     #  @reservation.day = date.day
#   end
#   if  not params[:hour_start].nil? # fullpick reservation
#     @reservation.time_start = params[:date1].to_date.to_time + params[:hour_start].to_i*3600
#     @reservation.time_end = params[:date2].to_date.to_time + params[:hour_end].to_i*3600 
#   end
#   
#   @reservation.created_by = current_user.id
#   @reservation.reservation_type = 'booking'
#   
#   @violated_rules = @reservation.violated_rules  
#   @success = (@violated_rules.size == 0)     
#   
#   if @success
#     @page_title = 'Reservation Successful'
#     @reservation.status = 'approved'
#   else  
#     @page_title = 'Reservation is Pending Approval'
#     @reservation.status = 'created'
#   end
#   
#   if @reservation.save 
#           render :partial => 'confirmation', :layout => 'application'
#           if not @reservation.instructor_id.nil?
#               ScheduleMailer.deliver_instructor_notification @reservation.instructor,@reservation
#           end
#   else
#      @page_title = 'Reservation Failed'
#      render :partial => 'failed', :layout => 'application'
#   end
# end

# Administrative page listing all reservations that need dispatcher's attention, showing
# controls for editing.approving and commenting on each reservation
def need_approval
  @reservations = Reservation.find(:all, :conditions => ["status = 'created'"],
                  :include => [:aircraft,:instructor,:creator],:order => '-reservations.id') 
  @page_title = 'Reservations Pending Approval' 
  case request.method
  when :post
    render :partial=>'need_approval'
  end
end

# # Changes status of reservation with id params[:id] to approved, if this action
# # does not violate any constraints (i.e. does not overlap with any other reservations
# # and has legal values for all fields
# def approve
#   @reservation = Reservation.find_by_id(params[:id])
#   if @reservation.instructor_id != current_user.id && !can_approve_reservations? then return end
#   old_status = @reservation.status
#   @reservation.status = 'approved'
#   if @reservation.save
#     flash[:notice] = 'Reservation Approved.'
#     redirect_to :back
#     return
#   else
#     @reservation.status = old_status
#   end      
#   render :partial => 'edit_reservation', :layout=>'application'
# end
# 
# # Changes status of reservation with id params[:id] to canceled
# def cancel
#   @reservation = Reservation.find_by_id(params[:id])
#   if @reservation.instructor_id != current_user.id && @reservation.created_by != current_user.id &&  !can_approve_reservations? then return end
#   @reservation.status = 'canceled'
#   if @reservation.save
#     flash[:notice] = 'Reservation Canceled.'
#     redirect_to :back
#     return
#   end      
#   render :partial => 'edit_reservation', :layout=>'application'
# end
# 
# # Undoes cancel action on reservation, setting reservation status to 'awaiting approval'
# def uncancel
#   @reservation = Reservation.find_by_id(params[:id])
#   if @reservation.instructor_id != current_user.id && @reservation.created_by != current_user.id &&  !can_approve_reservations? then return end
#   @reservation.status = 'created'
#   if @reservation.save
#     flash[:notice] = 'Undo Reservation Cancel.'
#     redirect_to :back
#     return
#   end      
#   render :partial => 'edit_reservation', :layout=>'application'
# end
# 
# # Adds rule with params[:rule_id] id to list of rules that do not 
# # apply to user with id params[:user_id]
# def add_rule_exception
#   return unless has_permission :can_edit_reservation_rules
#   @ex = ReservationRulesException.new
#   @ex.user_id = params[:user_id]
#   @ex.reservation_rule_id = params[:rule_id]
#   @ex.expiration_time = nil
#   if @ex.save
#     flash[:notice] = 'Exception Added.'
#     redirect_to :back
#   end
# end

# # Saves an edited reservation (with id params[:id]) if possible (all fields have legal values),
# # runs reservation rules against it and updates reservation's status according to the rules results 
# def update_reservation
#   @reservation = Reservation.find_by_id(params[:id])
#   if @reservation.instructor_id != current_user.id && @reservation.created_by != current_user.id &&  !can_approve_reservations? then return end
#   @reservation.time_start = params[:date1].to_date.to_time + params[:hour_start].to_i*3600
#   @reservation.time_end = params[:date2].to_date.to_time + params[:hour_end].to_i*3600 
#   
#    Reservation.transaction(@reservation) do
#      if @reservation.update_attributes(params[:reservation])
#         @violated_rules = @reservation.violated_rules  
#         @success = (@violated_rules.size == 0)     
#         
#         if @success
#           @reservation.status = 'approved'
#         else  
#           @reservation.status = 'created'
#         end
#         
#         if @reservation.save 
#           flash[:notice] = 'Reservation was successfully updated.'
#         else
#           flash[:notice] = 'Error updating reservation.'
#         end
#      else
#         flash[:notice] = 'Error updating reservation.'
#      end
#    end
#    @page_title = "Reservation #"+@reservation.id.to_s
#    render :partial => 'edit_reservation', :layout=>'application'
# end

# # Adds a comment to reservation with id params[:id], and redirects back to the request page.
# def add_comment
#   @reservation = Reservation.find_by_id(params[:id])
#   if @reservation.instructor_id != current_user.id && @reservation.created_by != current_user.id &&  !can_approve_reservations? then return end 
#   @doc = Document.new
#   @doc.body = params[:comment]
#   @doc.document_type = 'comment'
#   @doc.status='approved'
#   @doc.created_by = current_user
#   @doc.one_line_summary = ''
#   @doc.mime_type = 'text/plain'
#   @doc.last_updated_by = current_user
# 
#   Document.transaction(@doc) do
#     if @doc.save
#       @reservation.comments << @doc
#          redirect_to :back
#          return
#     end
#   end  
# end

# # master_schedule replacement (not completed yet)
# def schedule
#   @session[:schedule] ||= {}
#   @session[:schedule][:days] ||= '7'
#   @session[:schedule][:filter] ||= 'true'
#   @session[:schedule][:hidden_types] ||= []
# 
#   params.each_pair{|p,v|
#     @session[:schedule][p] = v unless @session[:schedule][p].nil?
#   }
# 
#   @date =  params[:date]==nil ? Date.today : params[:date].to_date 
#   @days =  @session[:schedule][:days].to_i  
#   @aircrafts = Aircraft.find(:all, 
#         :conditions => ['deleted = false'+ (@session[:schedule][:filter] ? " and office = #{current_user.office}":'')],
#         :include=>[:type,:default_office],:order=>'prioritized desc').group_by{|a| a.type}.sort.reverse
#   @instructors = Group.users_in_group_cond('instructor',"users.office=#{current_user.office}")
#   @page_title = 'Schedule'
# end
# 
# def reservation_data  
#   @days =  @session[:schedule][:days].to_i  
#   @from = params[:date]==nil ? Date.today : params[:date].to_date
#   @to = @from+@days
#   @reservations = Reservation.find(:all,
#                   :conditions => ["time_end > ? and time_start < ? and status!='canceled'",@from.to_time,@to.to_time])  
#    render :update do |page| 
#         page.send :record, "set_reservations(" + @reservations.to_json + ");" 
#    end 
# end
# 
# # master_schedule is responsible for displaying scheduling information in a 
# # schedule chart, with user-customizable reservation selection. The schedule
# # is accessible at two URLs - one for full-scheduling interface, and one where 
# # the schedule is displayed "full-screen" without site layout occupying extra space.
# #
# # master_schedule remembers values previously selected by users in user's session (number of days to show,
# # and categories of aircraft to hide). The page accepts following parameters:
# # params[:filter] - boolean, whether schedule should display only aircraft and instructors of user's local office 
# # params[:date] - Date.to_s, date of the first fday displayed on the schedule
# # params[:days] - integer, number of days to show on the schedule. 
# # params[:master] - boolean, whether the schedule is to be drawn for the master schedule page (as opposed to full scheduling interface)
# def master_schedule
#   @page_title = 'Master Schedule'
# 
#   if not params[:filter].nil?
#     @session[:filter_schedule] = params[:filter]
#   else
#     @session[:filter_schedule] ||= 'false'
#   end
#   @session[:hidden_types] ||= []
# 
#   @session[:schedule] ||= {}
#   @session[:schedule][:days] ||= 1
#   date = session[:schedule][:date]==nil ? Date.today : (Time.now - session[:schedule][:date_updated] > 3600 ? Date.today : session[:schedule][:date])
#   @from = params[:date]==nil ? date : params[:date].to_date#Date.new(params[:date][:year].to_i,params[:date][:month].to_i,params[:date][:day].to_i)
#   @to = params[:days]==nil ? @from+@session[:schedule][:days] : @from+params[:days].to_i
# 
#   session[:schedule][:date] = @from
#   session[:schedule][:date_updated] = Time.now
# 
#   @date = @from
#   if params[:days] != nil
#     @session[:schedule][:days] = params[:days].to_i
#   end
#   
#   #@cached_page=read_fragment(:controller=>'schedule',:action=>'master_schedule',:user=>current_user.id,:start=>@date,
#   #                    :days=>session[:schedule][:days],:master=>@master_schedule,:filter=>session[:filter_schedule],
#   #                    :office=>current_user.office)
#   
#  # if @cached_page.nil?
#     @from = @from.to_time
#     @to = @to.to_time
#   
#     @aircrafts = Aircraft.find(:all, :conditions => ['deleted = false'],:include=>[:type,:default_office],:order=>'prioritized desc')
#     @instructors = Group.users_in_group('instructor')
#     @reservations = Reservation.find(:all, :include=>[:creator,:instructor,:aircraft],:conditions => ["time_end > ? and time_start < ? and status!='canceled'",@from,@to])
#   
#     @user = current_user
#     if session[:filter_schedule]=='true'
#       @tmp = []
#       @instructors.each{|x|
#         if x.office.to_s == @user.office.to_s then @tmp<<x end
#       } 
#       @instructors= @tmp
#       @tmp = []
#       @aircrafts.each{|x|
#         if x.office.to_s == @user.office.to_s then @tmp<<x end
#       } 
#       @aircrafts= @tmp
#     end
#   
#   
#     @types = {}
#     @aircraft_count = 0
#     @aircrafts.each{|aircraft|
#       if session[:hidden_types].include? aircraft.aircraft_type then next end
#   #    if session[:filter_schedule]=='true' && aircraft.office!=@user.office then next end
#       @types[aircraft.aircraft_type] = aircraft.type
#       @aircraft_count = @aircraft_count + 1
#     }
#     
#     @types = @types.map{|k,v| v}
#     @types.sort!{|a,b| a.sort_value <=> b.sort_value}.reverse!
#     
#     @aircraft_reservations = []
#     @instructor_reservations = []
#     @reservations.each{|reservation|
#       if reservation.instructor_id != nil
#         @instructor_reservations << reservation
#       end
#       if reservation.aircraft_id != nil
#         @aircraft_reservations << reservation
#       end
#     } 
# 
#   #end
#   
#   if not params[:nolayout].nil?
#       render :action=>'master_schedule', :layout=>false
#       return
#   end
#   
#   case request.method
#   when :get
#     @master_schedule = true
#     render :action => 'master_schedule', :layout => false;
#   when :post #AJAX request
#     if params[:master] == 'true'
#       @master_schedule = true
#     end
#     render_partial 'master_schedule'
#   end
#   
# end
# 
# # Page displaying scheduling information (provided by master_schedule method) as
# # well as interface for creating a new reservation.
# def fullpick
#   @page_title = 'Make Reservation'
#   @reservation = Reservation.new
#   @reservation.created_by = current_user.id;
#   t = Time.new
#   @reservation.time_start =  Time.local(t.year,t.month,t.day,7)
#   @reservation.time_end =  Time.local(t.year,t.month,t.day,9)
#   case request.method
#   when :get
#     @location = current_user.office
#     render :partial => 'fullpick', :layout =>'application'  
#   when :post #AJAX call
#     params.each{|k,v|
#       if k.to_s != "controller" && k.to_s != "action" then 
#         @location = k.to_i 
#       end
#     }
#     render :partial => 'fullpick_form', :layout => false
#   end
# end

# Displays page with interface for adding an instructor block,
# a pattern of instructor blocks, and for clearing set of instructor blocks 
# between specified dates.
def create_instructor_block
  @page_title = 'Instructor Reservation Blocks'
  @reservation = Reservation.new
  @reservation.created_by = current_user.id;
  t = Time.new.tomorrow
  @reservation.time_start =  Time.local(t.year,t.month,t.day,10)
  @reservation.time_end =  Time.local(t.year,t.month,t.day,18)
  render :partial => 'instructor_block', :layout =>'application'  
end 

# Responds to request to create an instructor block specified by input params. Possible conflicts with existing reservations are searched, and
# if any found, the list of the conflicts is displayed with option to cancel all conflicting reservations. If
# no conflicts are found, the controller priceeds with saving the instructor block.
def new_instructor_block
  @page_title = 'Aircraft Reservation Block'
  @s_time = Time.local(params[:s_year],params[:s_month],params[:s_day],params[:s_hour])  
  @e_time = Time.local(params[:e_year],params[:e_month],params[:e_day],params[:e_hour])  
  @conflicts = Reservation.find(:all, :conditions =>
    ["time_end > ? and time_start < ? and status!='canceled' and status!='completed' and instructor_id=?",@s_time,@e_time,current_user.id])
  if @conflicts.size == 0
    save_instructor_block
    return
  end
end

# Saves an instructor block specified by params[:s_time] and params[:e_time] (with instructor being the current_user.
# Any conflicting reservations are canceled. 
def save_instructor_block
  if @s_time.nil?
    @s_time = params[:s_time].to_time
    @e_time = params[:e_time].to_time
  end
  @conflicts = Reservation.find(:all, :conditions =>
    ["time_end > ? and time_start < ? and status!='canceled' and status!='completed' and instructor_id=?",@s_time,@e_time,current_user.id])
  result = Reservation.transaction do
    @conflicts.each{|r|
      r.status = 'canceled'
      r.save
    }
    block = Reservation.new
    block.created_by = current_user.id
    block.instructor_id = current_user.id
    block.reservation_type = 'instructor_block'
    block.time_start = @s_time
    block.time_end = @e_time
    block.status = 'approved'
    block.save
    
    flash[:notice] = 'Block created successfully'
    redirect_to :controller => 'schedule', :action => 'create_instructor_block'
  end
  
  if not result
    flash[:notice] = 'Block creation failed'
    redirect_to :controller => 'schedule', :action => 'create_instructor_block'
  end
end

# Responds to request to create an instructor block pattern specified by input params. Possible conflicts with existing reservations are searched, and
# if any found, the list of the conflicts is displayed with option to cancel all conflicting reservations. If
# no conflicts are found, the controller priceeds with saving the instructor block pattern.
def new_instructor_block_pattern
  @page_title = 'New Reservation Block'
  @s = Time.local(params[:s_year],params[:s_month],params[:s_day]).to_date  
  @e = Time.local(params[:e_year],params[:e_month],params[:e_day]).to_date
  days = params[:days].keys.map{|x| x.to_i}
  @conflicts = []

  # should really be done in single SQL 
  Reservation.transaction do
    (@s..@e).each{|day|
      if not days.include? day.cwday then next end
      @s_time = day.to_time+params[:from].to_i*3600
      @e_time = day.to_time+params[:to].to_i*3600
      @conflicts += Reservation.find(:all, :conditions =>
        ["time_end > ? and time_start < ? and status!='canceled' and status!='completed' and instructor_id=?",@s_time,@e_time,current_user.id])
    }
  end
  
  params[:action] = :save_instructor_block_pattern
  params[:days].keys.each{|k|
    params["days[#{k}]"] = true
  }
  params[:days] = nil
  
  if @conflicts.size == 0
 #   render :text => 'ok'
    redirect_to params 
    return
  end
end

# Saves an instructor block pattern specified by params (with instructor being the current_user.
# Any conflicting reservations are canceled. 
def save_instructor_block_pattern

  @s = Time.local(params[:s_year],params[:s_month],params[:s_day]).to_date  
  @e = Time.local(params[:e_year],params[:e_month],params[:e_day]).to_date
  days = params[:days].keys.map{|x| x.to_i}

  # should really be done in single SQL 
  result = Reservation.transaction do
    (@s..@e).each{|day|
      if not days.include? day.cwday then next end
      @s_time = day.to_time+params[:from].to_i*3600
      @e_time = day.to_time+params[:to].to_i*3600
      @conflicts = Reservation.find(:all, :conditions =>
        ["time_end > ? and time_start < ? and status!='canceled' and status!='completed' and instructor_id=?",@s_time,@e_time,current_user.id])

       @conflicts.each{|r|
         r.status = 'canceled'
         r.save
       }
       block = Reservation.new
       block.created_by = current_user.id
       block.instructor_id = current_user.id
       block.reservation_type = 'instructor_block'
       block.time_start = @s_time
       block.time_end = @e_time
       block.status = 'approved'
       block.save
    }

     flash[:notice] = 'Block created successfully'
     redirect_to :controller => 'schedule', :action => 'create_instructor_block'
   end

   if not result
     flash[:notice] = 'Block creation failed'
     redirect_to :controller => 'schedule', :action => 'create_instructor_block'
   end
end 

# Clears a set of instructor blocks for current_user between dates specified in params. (Changing their status to 'canceled')
def clear_instructor_blocks
  @s_time = Time.local(params[:s_year],params[:s_month],params[:s_day],params[:s_hour])
  @e_time = Time.local(params[:e_year],params[:e_month],params[:e_day],params[:e_hour])

  result = Reservation.transaction do
      @blocks = Reservation.find(:all, :conditions =>
        ["time_end > ? and time_start < ? and reservation_type = 'instructor_block' and instructor_id=?",@s_time,@e_time,current_user.id])

       @blocks.each{|r|
         if r.time_start < @s_time and r.time_end>@e_time
           r.status = 'canceled'
           r.save
           r1 = Reservation.new(r.attributes)
           r1.status='approved'
           r1.time_end = @s_time
           r2 = Reservation.new(r.attributes)
           r2.status='approved'
           r2.time_start = @e_time
           r1.save
           r2.save
         elsif r.time_start > @s_time and r.time_end>@e_time
           r.time_start = @e_time
           r.save
         elsif r.time_start < @s_time and r.time_end<@e_time
           r.time_end = @s_time
           r.save
         else
           r.status = 'canceled'
           r.save
         end
       }
       flash[:notice] = 'Blocks cleared successfully'
      redirect_to :controller => 'schedule', :action => 'create_instructor_block'
    end

    if not result
      flash[:notice] = 'Block clearing failed'
      redirect_to :controller => 'schedule', :action => 'create_instructor_block'
    end
  
end

# # Sets status of instructor_block with id params[:id] to 'canceled', after checking approproate permissions.
# # The controller is referred to from master_schedule page, which has 'cancel instructor block' link in 
# # instructor block tooltips. 
# def cancel_block
#   res = Reservation.find(params[:id])
#   if res.instructor_id != current_user.id && res.created_by != current_user.id &&  !can_approve_reservations? then return end
#   res.status='canceled'
#   res.save
#   master_schedule
# end

# Displays page with interface for adding an aircraf block
def create_aircraft_block 
  @aircraft_id = params[:aircraft_id]
  @page_title = 'Make Reservation Block for '+Aircraft.find_by_id(@aircraft_id).identifier
  @reservation = Reservation.new
  @reservation.created_by = current_user.id;
  t = Time.new.tomorrow
  @reservation.time_start =  Time.local(t.year,t.month,t.day,10)
  @reservation.time_end =  Time.local(t.year,t.month,t.day,18)
  render :partial => 'aircraft_block', :layout =>'application'  
end 

# Responds to request to create an aircraft block specified by input params. Possible conflicts with existing reservations are searched, and
# if any found, the list of the conflicts is displayed with option to cancel all conflicting reservations. If
# no conflicts are found, the controller priceeds with saving the aircraft block.
def new_aircraft_block
  return unless has_permission :can_manage_aircraft
  @page_title = 'New Reservation Block'
  @s_time = Time.local(params[:s_year],params[:s_month],params[:s_day],params[:s_hour])  
  @e_time = Time.local(params[:e_year],params[:e_month],params[:e_day],params[:e_hour])  
  @conflicts = Reservation.find(:all, :conditions =>
    ["time_end > ? and time_start < ? and status!='canceled' and status!='completed' and aircraft_id=?",@s_time,@e_time,params[:aircraft_id]])
  if @conflicts.size == 0
    save_aircraft_block
    return
  end
end

# Saves an aircraft block specified by params[:s_time] and params[:e_time] (with aircraft being the aircraft with 
# id params[:aircraft_id].
# Any conflicting reservations are canceled. 
def save_aircraft_block
  return unless has_permission :can_manage_aircraft
  if @s_time.nil?
    @s_time = params[:s_time].to_time
    @e_time = params[:e_time].to_time
  end
  @conflicts = Reservation.find(:all, :conditions =>
    ["time_end > ? and time_start < ? and status!='canceled' and status!='completed' and aircraft_id=?",@s_time,@e_time,params[:aircraft_id]]) 
    
  result = Reservation.transaction do
    @conflicts.each{|r|
      r.status = 'canceled'
      r.save
    }
    block = Reservation.new
    block.created_by = current_user.id
    block.aircraft_id = params[:aircraft_id]
    block.reservation_type = 'aircraft_block'
    block.time_start = @s_time
    block.time_end = @e_time
    block.status = 'approved'
    block.save
    
    flash[:notice] = 'Block created successfully'
    redirect_to :controller => 'schedule', :action => 'create_aircraft_block', :aircraft_id => params[:aircraft_id]
  end
  
  if not result
    flash[:notice] = 'Block creation failed'
    redirect_to :controller => 'schedule', :action => 'create_aircraft_block', :aircraft_id => params[:aircraft_id]
  end
end

# Responds to request to create an aircraft block pattern specified by input params. Possible conflicts with existing reservations are searched, and
# if any found, the list of the conflicts is displayed with option to cancel all conflicting reservations. If
# no conflicts are found, the controller priceeds with saving the aircraft block pattern.
def new_aircraft_block_pattern
  @page_title = 'New Reservation Block'
  @s = Time.local(params[:s_year],params[:s_month],params[:s_day]).to_date  
  @e = Time.local(params[:e_year],params[:e_month],params[:e_day]).to_date
  days = params[:days].keys.map{|x| x.to_i}
  @conflicts = []

  # should really be done in single SQL 
  Reservation.transaction do
    (@s..@e).each{|day|
      if not days.include? day.cwday then next end
      @s_time = day.to_time+params[:from].to_i*3600
      @e_time = day.to_time+params[:to].to_i*3600
      @conflicts += Reservation.find(:all, :conditions =>
        ["time_end > ? and time_start < ? and status!='canceled' and status!='completed' and aircraft_id=?",@s_time,@e_time,params[:aircraft_id]])
    }
  end
  
  params[:action] = :save_aircraft_block_pattern
  params[:days].keys.each{|k|
    params["days[#{k}]"] = true
  }
  params[:days] = nil
  
  if @conflicts.size == 0
 #   render :text => 'ok'
    redirect_to params 
    return
  end
end

# Saves an aircraft block pattern specified by params (for aircraft with id params[:id].
# Any conflicting reservations are canceled. 
def save_aircraft_block_pattern

  @s = Time.local(params[:s_year],params[:s_month],params[:s_day]).to_date  
  @e = Time.local(params[:e_year],params[:e_month],params[:e_day]).to_date
  days = params[:days].keys.map{|x| x.to_i}

  # should really be done in single SQL 
  result = Reservation.transaction do
    (@s..@e).each{|day|
      if not days.include? day.cwday then next end
      @s_time = day.to_time+params[:from].to_i*3600
      @e_time = day.to_time+params[:to].to_i*3600
      @conflicts = Reservation.find(:all, :conditions =>
        ["time_end > ? and time_start < ? and status!='canceled' and status!='completed' and aircraft_id=?",@s_time,@e_time,params[:aircraft_id]])

       @conflicts.each{|r|
         r.status = 'canceled'
         r.save
       }
       block = Reservation.new
       block.created_by = current_user.id
       block.aircraft_id = params[:aircraft_id]
       block.reservation_type = 'aircraft_block'
       block.time_start = @s_time
       block.time_end = @e_time
       block.status = 'approved'
       block.save
    }

     flash[:notice] = 'Block created successfully'
     redirect_to :controller => 'schedule', :action => 'create_aircraft_block',:aircraft_id => params[:aircraft_id]
   end

   if not result
     flash[:notice] = 'Block creation failed'
     redirect_to :controller => 'schedule', :action => 'create_aircraft_block',:aircraft_id => params[:aircraft_id]
   end
end 

# Clears a set of aircraft blocks for aircraft with id params[:id] between dates specified in params. (Changing their status to 'canceled')
def clear_aircraft_blocks
  @s_time = Time.local(params[:s_year],params[:s_month],params[:s_day],params[:s_hour])
  @e_time = Time.local(params[:e_year],params[:e_month],params[:e_day],params[:e_hour])

  result = Reservation.transaction do
      @blocks = Reservation.find(:all, :conditions =>
        ["time_end > ? and time_start < ? and reservation_type = 'aircraft_block' and aircraft_id=?",@s_time,@e_time,params[:aircraft_id]])

       @blocks.each{|r|
          if r.time_start < @s_time and r.time_end>@e_time
            r.status = 'canceled'
            r.save
            r1 = Reservation.new(r.attributes)
            r1.time_end = @s_time
            r2 = Reservation.new(r.attributes)
            r2.time_start = @e_time
            r1.save
            r2.save
          elsif r.time_start > @s_time and r.time_end>@e_time
            r.time_start = @e_time
            r.save
          elsif r.time_start < @s_time and r.time_end<@e_time
            r.time_end = @s_time
            r.save
          else
            r.status = 'canceled'
            r.save
          end
       }
       flash[:notice] = 'Blocks cleared successfully'
       redirect_to :controller => 'schedule', :action => 'create_aircraft_block',:aircraft_id => params[:aircraft_id]
   end

    if not result
      flash[:notice] = 'Block clearing failed'
      redirect_to :controller => 'schedule', :action => 'create_aircraft_block',:aircraft_id => params[:aircraft_id]
    end
  
end

# Similar to master_schedule this method renders a page with scheduling information
# Information is provided for a single day, and the output is in printer-ready 
# HTML table.
def printable_schedule
  session[:hidden_types] ||= []
  
  @instructors = Group.users_in_group('instructor')
  @aircrafts = Aircraft.find(:all, :conditions => ['deleted = false'])
  
  from = params[:date].to_date
  to = from.next
  @year = from.year
  @month = from.month
  @day = from.day
  @types = {}
  @aircrafts.each{|aircraft|
 #   if session[:hidden_types].include? aircraft.aircraft_type then next end
    @types[aircraft.aircraft_type] = aircraft.type
  }
  
  @types = @types.map{|k,v| v}
  @types.sort!{|a,b| a.sort_value <=> b.sort_value}.reverse!
  
  @instructor_reservations = {}
  @instructors.each{|instructor|
         @instructor_reservations[instructor.id] = Reservation.instructor_reservations instructor.id,from,to
  }
  
  @aircraft_reservations = {}
  @aircrafts.each{|aircraft|
         @aircraft_reservations[aircraft.id] = Reservation.aircraft_reservations aircraft.id,from,to
  }
  render :action => 'printable_schedule', :layout => false;
end

# # Marks an aircraft type as hidden for current_user (to prevent it showing up when rendererd through master_schedule)
# def hide_type
#   session[:hidden_types] << params[:type_id].to_i
#   master_schedule
# end
# 
# # Marks all aircraft types as not hidden for current_user
# def unhide_types
#   session[:hidden_types] = []
#   master_schedule
# end

# Reassigns reservation from one aircraft to another. The inputs are of the form params[:drag] = 'abarXX' 
# where XX is original aircraft id, and params[:drop] = 'aYY' where YY is new (reassigned) 
# aircraft id. The method responds to AJAX calls from master_schedule component. 
def drag_drop_reservation
   return unless has_permission :can_approve_reservations
   drag = params[:drag][4..-1]
   drop = params[:drop][1..-1]
   r = Reservation.find(drag)
   r.aircraft_id = drop
   r.save
   params[:date] = params[:sdate].to_date
   master_schedule
end

end
