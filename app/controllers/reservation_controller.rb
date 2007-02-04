class ReservationController < ApplicationController
  
  before_filter :login_required
  before_filter :redirect_flash_to_sidebar,:except=>[:swap]
  before_filter :require_supported_browser
  before_filter :require_schedule_access
  
  def list
    user_id =  current_user.id
    @page_title = "Reservations for "+User.find_by_id(user_id).full_name

    if params[:showall]    
      @reservation_pages, @reservations = paginate :reservations, :conditions=>["created_by = ? and reservation_type='booking'",user_id],:order=>'time_start desc', :per_page => 50
    else
      @reservations = Reservation.find(:all,:conditions=>["created_by = ? and reservation_type='booking' and status!='canceled' and time_end>?",user_id,Time.now],:order=>'time_start desc')
    end
    
    case request.method
    when :post: render :partial=>'list',:layout=>false
    end
  end
  
  def instructor
    user_id =  current_user.id
    @page_title = "Instructor Reservations for "+User.find_by_id(user_id).full_name

    if params[:showall]   
      @reservation_pages, @reservations = paginate :reservations, :conditions=>["instructor_id = ? and reservation_type='booking'",user_id],:order=>'time_start desc', :per_page => 50
    else
      @reservations = Reservation.find(:all,:conditions=>["instructor_id = ? and reservation_type='booking' and status!='canceled' and time_end>?",user_id,Time.now],:order=>'time_start desc')
    end
    
    case request.method
    when :post: render :partial=>'instructor',:layout=>false
    end
  end
  

  def new
    @page_title = 'Reservation Schedule'
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
    @reservation = Reservation.new(params[:reservation],current_user)
    if admin?
      @reservation.override_acceptance_rules
    else
      @reservation.created_by = current_user.id
    end
    session[:schedule][:date] = @reservation.time_start.to_date unless @reservation.time_start.nil?
    if @reservation.save
      
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
    return unless @reservation.pilot.id == current_user or @reservation.instructor_id == current_user.id or has_permission(:can_approve_reservations)
    @violated_rules = @reservation.violated_rules
    render :partial=>'edit_reservation',:layout=>false
  end

  def update
    @reservation = Reservation.find_by_id params[:id]
    return unless @reservation.pilot.id == current_user or @reservation.instructor_id == current_user.id or has_permission(:can_approve_reservations)
    
    if admin?
      @reservation.override_acceptance_rules
    end
        
    if not has_permission(:can_approve_reservations) and @reservation.status=='approved' 
      @reservation.status = 'created'
    end

    if @reservation.update_attributes(params[:reservation])
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
    return unless @reservation.pilot.id == current_user or @reservation.instructor_id == current_user.id or has_permission(:can_approve_reservations)
    
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
  
    @reservation.status = 'approved'
    if @reservation.save
      flash[:notice] = 'Approved.'
      @refresh_content = true
    end
    render :partial=>'edit_reservation',:layout=>false
  end
  
  # Adds a comment to reservation with id params[:id]
  def add_comment
    @reservation = Reservation.find_by_id(params[:id])
    return unless @reservation.pilot.id == current_user or @reservation.instructor_id == current_user.id or has_permission(:can_approve_reservations) 
    
    if @reservation.instructor_id != current_user.id && @reservation.created_by != current_user.id &&  !can_approve_reservations? then return end 
    comment = ReservationComment.new(params[:comment],current_user)
    @reservation.comments << comment
    @refresh_content = true
    render :partial=>'edit_reservation',:layout=>false
  end
  
  def add_rule_exception
    return unless has_permission :can_edit_reservation_rules
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
    session[:schedule] ||= {}
    session[:schedule][:filter] ||= 'true'
    session[:schedule][:filter] = params[:office_filter] unless params[:office_filter].nil?
    
    params.each_pair{|p,v|
      session[:schedule][p] = v unless @session[:schedule][p].nil?
    }

    process_date_params

    @aircrafts = Aircraft.find(:all, 
          :conditions => ['deleted = false'+ (session[:schedule][:filter]=="true" ? " and office = #{current_user.office}":'')],
          :include=>[:type,:default_office],:order=>'prioritized desc')
    if session[:schedule][:filter]=="true"
      @instructors = Group.users_in_group_cond('instructor',"users.office=#{current_user.office}")
    else
      @instructors = Group.users_in_group('instructor')
    end

    @types = {}
    @aircrafts.each{|aircraft| @types[aircraft.aircraft_type] = aircraft.type    }
    @types = @types.map{|k,v| v}
    @types.sort!{|a,b| a.sort_value <=> b.sort_value}.reverse!

    render :partial=>'schedule'
  end
    
  def update_schedule  
    process_date_params
  
    @from = @date
    @to = @from+1
    @reservations = Reservation.find(:all,
                    :conditions => ["time_end > ? and time_start < ? and status!='canceled'",@from.to_time,@to.to_time])  
     render :update do |page| 
          page.send :record, "set_schedule_date(" + (@from.to_time.to_i*1000).to_s + ");" 
          page.send :record, "set_reservations(" + @reservations.to_json + ");" 
     end 
  end
  
  def swap
    return unless has_permission :admin
    @page_title = 'Swap Reservations'
    if request.method==:post
      noerrors = true
      success = Reservation.transaction do
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
          noerrors &&= r.save
        }
        r2.each{|r|
          r.override_acceptance_rules
          status[r.id]=r.status
          r.status='canceled'
          r.aircraft_id = a1.id
          noerrors &&= r.save
        }
        r1.each{|r|
          r.override_acceptance_rules
          r.status = status[r.id]
          noerrors &&= r.save
        }
        r2.each{|r|
          r.override_acceptance_rules
          r.status = status[r.id]
          noerrors &&= r.save
        }        
      end
      if success and noerrors
        flash[:notice] = 'Reservations swapped.'
      else
        flash[:warning] = 'There was a problem with the swap, because of overlapping reservations. Try a different \'From\' date.' 
      end
    end
  end
  
  private
  
  def redirect_flash_to_sidebar
    @suppress_flash = true
  end
  
  def process_date_params
    date = session[:schedule][:date]==nil ? Date.today : (Time.now - session[:schedule][:date_updated] > 3600 ? Date.today : session[:schedule][:date])
    @date = params[:date]==nil ? date : params[:date].to_date

    session[:schedule][:date] = @date
    session[:schedule][:date_updated] = Time.now
  end
  
  
end