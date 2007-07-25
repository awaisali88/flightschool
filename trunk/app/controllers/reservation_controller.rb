class ReservationController < ApplicationController
  
  before_filter :login_required
  before_filter :redirect_flash_to_sidebar,:except=>[:swap,:preferences]
  before_filter :require_supported_browser
  before_filter :require_schedule_access
  before_filter :process_date_params, :only=>[:schedule,:instructor_schedule,:update_schedule]
  after_filter :compress, :only=>[:update_schedule]
  
  def list
    user_id =  current_user.id
    @page_title = "Reservations for "+User.find_by_id(user_id).full_name

    if params[:offset]==nil
      @reservations = Reservation.find(:all,:conditions=>["created_by = ? and reservation_type='booking' and time_end>?",user_id,Time.now],:order=>'time_start',:limit=>50)
    else
      @reservations = Reservation.find(:all,:conditions=>["created_by = ? and reservation_type='booking'",user_id],:offset=>params[:offset],:order=>'time_start',:limit=>50)
    end
    first = @reservations[0]
    if first.nil?
      if params[:offset]==nil
        @before = Reservation.count(:conditions=>["created_by = ? and reservation_type='booking'",user_id])
      else
        @before = 0
      end
      @after = 0
    else
      @before = Reservation.count(:conditions=>["created_by = ? and reservation_type='booking' and (time_start<? or (time_start=? and id<?))",user_id,first.time_start,first.time_start,first.id])
      @after = Reservation.count(:conditions=>["created_by = ? and reservation_type='booking' and (time_start>? or (time_start=? and id>?))",user_id,first.time_start,first.time_start,first.id])
    end
    
    case request.method
    when :post: render :partial=>'list',:layout=>false
    end
  end
  
  def instructor
    user_id =  current_user.id
    @page_title = "Instructor Reservations for "+User.find_by_id(user_id).full_name

    if params[:offset]==nil
      @reservations = Reservation.find(:all,:conditions=>["instructor_id = ? and reservation_type='booking' and time_end>?",user_id,Time.now],:order=>'time_start',:limit=>50)
    else
      @reservations = Reservation.find(:all,:conditions=>["instructor_id = ? and reservation_type='booking'",user_id],:offset=>params[:offset],:order=>'time_start',:limit=>50)
    end
    first = @reservations[0]
    if first.nil?
      if params[:offset]==nil
        @before = Reservation.count(:conditions=>["instructor_id = ? and reservation_type='booking'",user_id])
      else
        @before = 0
      end
      @after = 0
    else
      @before = Reservation.count(:conditions=>["instructor_id = ? and reservation_type='booking' and (time_start<? or (time_start=? and id<?))",user_id,first.time_start,first.time_start,first.id])
      @after = Reservation.count(:conditions=>["instructor_id = ? and reservation_type='booking' and (time_start>? or (time_start=? and id>?))",user_id,first.time_start,first.time_start,first.id])
    end
    
    case request.method
    when :post: render :partial=>'instructor',:layout=>false
    end
  end
  

  def new
    @page_title = 'Reservation Schedule'
    session[:schedule] ||= {}
    session[:schedule][:showing_instructor_block_page] = nil
    @reservation = Reservation.new({'created_by'=>current_user.id}.merge(session[:last_reservation] || {}))
    if not @reservation.time_start.nil?
      if @reservation.time_start > Time.now
        @reservation.time_start = @reservation.time_end + 2.hours
        @reservation.time_end = @reservation.time_start + 2.hours
      else
        @reservation.time_start = Date.today.to_time + (24+7).hours
        @reservation.time_end = Date.today.to_time + (24+9).hours
      end
    else
      @reservation.time_start = Date.today.to_time + (24+7).hours
      @reservation.time_end = Date.today.to_time + (24+9).hours
    end
  end

  def create
    @page_title = 'Reservation Schedule'
    session[:schedule] ||= {}
    session[:schedule][:showing_instructor_block_page] = nil
    @reservation = Reservation.new(params[:reservation],current_user)
    if admin? or instructor?
      @reservation.override_acceptance_rules
    else
      @reservation.created_by = current_user.id
      @reservation.status = 'created'
    end
    session[:schedule][:date] = @reservation.time_start.to_date unless @reservation.time_start.nil?

    success = false
    Reservation.transaction do
      success = @reservation.save
    end
    
    if success
      #send instructor an email to let him/her know about the new reservation
      if not @reservation.instructor_id.nil?
          ScheduleMailer.deliver_instructor_notification @reservation.instructor,@reservation
      end
      
      #add instructor block if the reservation is made for an instructor
      if @reservation.pilot.in_group? 'instructor'
        block = Reservation.new(@reservation.attributes)
        block.instructor_id = @reservation.pilot.id
        block.aircraft_id = nil
        block.status='approved'
        block.reservation_type='instructor_block'
        block.save
      end
      
      @refresh_content = true
      session[:last_reservation] = params[:reservation]
      @violated_rules = @reservation.violated_rules
      if @violated_rules.size>0
        flash[:notice] = 'Created.'
        render :action=>'create'
      else
        flash[:notice] = 'Saved: '+@reservation.reservation_summary
        @reservation = Reservation.new(@reservation.attributes)
        @reservation.time_start = @reservation.time_end + 2.hours
        @reservation.time_end = @reservation.time_start + 2.hours
        render :action=>'new'
      end
    else
      render :action=>'new'
    end
  end
  
  def edit
    @reservation = Reservation.find_by_id params[:id]
    return unless @reservation.pilot == current_user or @reservation.instructor_id == current_user.id or has_permission(:can_approve_reservations)
    @violated_rules = @reservation.violated_rules
    render :partial=>'edit_reservation',:layout=>false
  end

  def update
    @reservation = Reservation.find_by_id params[:id]
    return unless @reservation.pilot == current_user or @reservation.instructor_id == current_user.id or has_permission(:can_approve_reservations)
    
    if admin? or instructor?
      @reservation.override_acceptance_rules
    else
      @reservation.created_by = current_user.id

      if @reservation.status=='approved' 
        @reservation.status = 'created'
      end
    end
        
    success = false
    Reservation.transaction do
      success = @reservation.update_attributes(params[:reservation])
    end
    
    if success
      session[:last_reservation] = params[:reservation]
      flash[:notice] = 'Updated.'
      @violated_rules = @reservation.violated_rules    
      @refresh_content = true #this will force the reload of the page 'content' - i.e. everything BUT the reservation box
    end


    case request.method
    when :post:
      render :partial=>'edit_reservation',:layout=>false
    end
  end
  
  def cancel
    @reservation = Reservation.find_by_id params[:id]
    return unless @reservation.pilot == current_user or @reservation.instructor_id == current_user.id or has_permission(:can_approve_reservations)
    
     if admin?
        @reservation.override_acceptance_rules
      end
    
    oldstatus = @reservation.status
    @reservation.status = 'canceled'
    if @reservation.save
      flash[:notice] = 'Canceled.'
      @refresh_content = true
    else
      @reservation.status = oldstatus
    end
   render :partial=>'edit_reservation',:layout=>false
  end

  def approve
    @reservation = Reservation.find_by_id params[:id]
    return unless has_permission :can_approve_reservations 
  
    oldstatus = @reservation.status
    @reservation.status = 'approved'

    if admin?
       @reservation.override_acceptance_rules
     end
    
    success = false
    Reservation.transaction do
      success = @reservation.save
    end
    
    if success
      flash[:notice] = 'Approved.'
      @refresh_content = true
    else
      @reservation.status = oldstatus
    end

    render :partial=>'edit_reservation',:layout=>false
  end
  
  # Adds a comment to reservation with id params[:id]
  def add_comment
    @reservation = Reservation.find_by_id(params[:id])
    return unless @reservation.pilot == current_user or @reservation.instructor_id == current_user.id or has_permission(:can_approve_reservations) 
    
    if @reservation.instructor_id != current_user.id && @reservation.created_by != current_user.id &&  !can_approve_reservations? then return end 
    comment = ReservationComment.new(params[:comment],current_user)
    @reservation.comments << comment
    @refresh_content = true
    render :partial=>'edit_reservation',:layout=>false
  end
  
  def add_rule_exception
    return unless has_permission :can_edit_reservation_rules
    @reservation = Reservation.find_by_id(params[:reservation_id])
    ex = ReservationRulesException.new
    ex.user_id = params[:user_id]
    ex.reservation_rule_id = params[:rule_id]
    if ex.save
      flash[:notice] = 'Exception Added.'
      @refresh_content = true
    end
    render :partial=>'edit_reservation',:layout=>false
  end
  
  def schedule
    @aircrafts = Aircraft.find(:all, 
          :conditions => ['deleted = false'+ (session[:schedule][:filter]=="true" ? " and office = #{current_user.office}":'')],
          :include=>[:type,:default_office],:order=>'office, prioritized desc, identifier')
    if session[:schedule][:filter]=="true"
      @instructors = Group.users_in_group_cond('instructor',"users.office=#{current_user.office}")
    else
      @instructors = Group.users_in_group('instructor')
    end

    @types = {}
    @aircrafts.each{|aircraft| @types[aircraft.aircraft_type] = aircraft.type    }
    @types = @types.map{|k,v| v}
    @types.sort!{|a,b| a.sort_value <=> b.sort_value}.reverse!
    
    session[:schedule][:preferences] ||= {}
    type_prefs = session[:schedule][:preferences][:types]
    instructor_prefs = session[:schedule][:preferences][:instructors]
    if not(type_prefs.nil?) and type_prefs.size>0
      @types.delete_if{|type| type_prefs[type.id.to_s].nil? }
      @aircrafts.delete_if{|aircraft| type_prefs[aircraft.type.id.to_s].nil?}
    end
    if not(instructor_prefs.nil?) and instructor_prefs.size>0
      @instructors.delete_if{|instructor| instructor_prefs[instructor.id.to_s].nil? }
    end

    if (session[:schedule][:showing_instructor_block_page] != nil)
       @aircrafts = []
        @types = []
        @instructors = User.find_all_by_id current_user.id
    end
    

    render :partial=>'schedule'
  end
    
  def update_schedule    
    @from = @date
    @to = @from + @days
    @reservations = Reservation.find(:all,:include=>[:pilot],
                    :conditions => ["time_end > ? and time_start < ? and status!='canceled'",@from.to_time,@to.to_time])  
     render :update do |page| 
          page.send :record, "set_schedule_date(#{@from.year},#{@from.month},#{@from.day},#{@from-Date.new(2000)});" 
          page.send :record, "set_reservations([" + @reservations.map{|r| r.cached_json_rep }.join(',') + "]);" 
     end 
  end
  
  def swap
    return unless has_permission :admin
    @page_title = 'Swap Reservations'
    if request.method==:post
      begin 
        Reservation.transaction do
          status = {}
          a1 = Aircraft.find_by_id params[:aircraft1]
          a2 = Aircraft.find_by_id params[:aircraft2]
          from = Time.local(params[:s_year],params[:s_month],params[:s_day],params[:s_hour])  
          r1 = Reservation.find :all, :conditions=>['aircraft_id=? and time_start>?',a1.id,from]
          r2 = Reservation.find :all, :conditions=>['aircraft_id=? and time_start>?',a2.id,from]
          r1.each{|r|
            r.override_acceptance_rules
            status[r.id]=r.status
            r.status='canceled'
            r.aircraft_id = a2.id
            r.save!
          }
          r2.each{|r|
            r.override_acceptance_rules
            status[r.id]=r.status
            r.status='canceled'
            r.aircraft_id = a1.id
            r.save!
          }
          r1.each{|r|
            r.override_acceptance_rules
            r.status = status[r.id]
            r.save!
          }
          r2.each{|r|
            r.override_acceptance_rules
            r.status = status[r.id]
            r.save!
          }        
        end
        flash[:notice] = 'Reservations swapped.'
      rescue
        flash[:warning] = 'There was a problem with the swap, because of overlapping reservations. Try a different \'From\' date.' 
      end
    end
  end
  
  # page for editing per-user schedule view preferences
  def preferences
    @page_title = 'Schedule View Preferences'
    @instructors = Group.users_in_group('instructor')
    @aircraft_types = AircraftType.find(:all)
    @offices = Office.find :all
    @instructors.sort!{|a,b| a.first_names<=>b.first_names}
    @aircraft_types.sort!{|a,b| a.type_name<=>b.type_name}
        
    if request.method == :post
      session[:schedule][:preferences] = params[:preferences]
      flash[:notice] = 'Preferences Saved.'
    end
    
    session[:schedule][:preferences] ||= {}
    session[:schedule][:preferences][:types] ||= {}
    session[:schedule][:preferences][:instructors] ||= {}
    
  end
  
  private
  
  def redirect_flash_to_sidebar
    @suppress_flash = true
  end
  
  def process_date_params
    session[:schedule] ||= {}
    session[:schedule][:filter] ||= 'true'
    session[:schedule][:filter] = params[:office_filter] unless params[:office_filter].nil?
        
    date = session[:schedule][:date]==nil ? Date.today : (Time.now - session[:schedule][:date_updated] > 3600 ? Date.today : session[:schedule][:date])
    @date = params[:date]==nil ? date : params[:date].to_date
    days = session[:schedule][:days]==nil ? 1 : session[:schedule][:days]
    @days = params[:days]==nil ? days : params[:days].to_i

    session[:schedule][:date] = @date
    session[:schedule][:date_updated] = Time.now
    session[:schedule][:days] = @days
  end
  
  
end