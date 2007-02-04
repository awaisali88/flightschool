#####################################################################################
#
# BillingController implements the accounting functionality of the system,
# providing ways to enter accounting data, and view individual and site-wide reports
# based on the entered data.
#
# Authors:: Lev Popov levpopov@mit.edu
# 
#####################################################################################

class BillingController < ApplicationController

before_filter :force_single_column_layout

# page for generating raw data reports
def raw_report
  return unless has_permission :can_do_billing
  @page_title = 'Generate Raw Data Report'
  @from = Time.now.beginning_of_month
  @to = @from.next_month
end

# sends raw data exported as CSV file to user. Typically called as a POST from 
# raw_report page.
def raw_export
  return unless has_permission :can_do_billing
  case request.method
  when :get
    @page_title = 'Generate Raw Data Report'
    @from = Time.now.beginning_of_month
    @to = @from.next_month
  when :post
    from = Date.new(params[:from][:year].to_i,params[:from][:month].to_i)
    to = Date.new(params[:to][:year].to_i,params[:to][:month].to_i)
    @records = BillingCharge.find(:all,:conditions=>['billing_charges.created_at > ? and billing_charges.created_at < ?',from,to],
      :order=>['billing_charges.id'],:include=>[:pilot,:instructor,:aircraft])
    report = StringIO.new
    CSV::Writer.generate(report, ',') do |csv|
      csv << %w(Timestamp Pilot Amount Total Type Note Aircraft Aircraft_Rate Instructor Instructor_Rate Hobbs_Start Hobbs_End Tach Ground_Instruction)
      @records.each do |r|
          csv << [r.created_at, r.pilot.full_name_with_id, r.charge_amount, r.running_total, 
                  r.type.to_s == 'FlightRecord' ? 'flight/ground instruction' : r.type, r.notes, r.aircraft_id.nil? ? nil : r.aircraft.identifier, 
                  r.aircraft_rate, r.instructor_id.nil? ? nil : r.instructor.full_name_with_id,
                  r.instructor_rate, r.hobbs_start, r.hobbs_end, r.tach_end, r.ground_instruction_time]
        end
      end

      report.rewind
      send_data(report.read,
        :type => 'text/csv; charset=iso-8859-1; header=present',
        :filename => 'report.csv')
  end
end

# page for entering non-flight billing charges (such as supplies, deposits, etc)
# handles both GETs and POSTs
def new_record
  return unless has_permission :can_do_billing
  @page_title = 'New Billing Record'
  
  @record = BillingCharge.new 
  @users = User.find(:all,:conditions=>['account_suspended = false'])
  
  case request.method
    when :post
      @record = BillingCharge.new(params[:record],current_user)    
      if @record.save
        flash[:notice] = "[#{@record.created_at.min}:#{@record.created_at.sec}] Record Created: #{@record.pilot.full_name}, $#{@record.charge_amount}"
        redirect_to :back
      else
       flash[:warning] = 'Error Creating Billing Record'
      end
   end
  
end

def test
  
end

# page for entering flight-related billing charges
# Handles both GETs and POSTs
def new_flight_record
  return unless has_permission :can_do_billing
  @page_title = 'New Flight Record Sheet'
  
    @users = User.find(:all,:conditions=>['account_suspended = false'])
  @instructors = Group.users_in_group('instructor')
  @aircrafts = Aircraft.find(:all,:conditions=>['deleted = false'])
    
end

def create_records
  return unless has_permission :can_do_billing
  errors_present = false
  record_count = 0
  FlightRecord.transaction do
    render :update do |page|         
      i = 1
      while params["rec#{i}"]!=nil
        if params["rec#{i}"][:charge_amount]=="" #empty row - ignore
          page.send :record, "$('rec#{i}').style.background='grey'"
          i=i+1
          next
        end
        
        record = FlightRecord.new(params["rec#{i}"],params[:aircraft],current_user)
        begin
          record.flight_date = Time.local(params[:year],params["month#{i}"],params["day#{i}"])
        rescue
        end
        if record.save
            record_count = record_count+1
            page.send :record, "$('rec#{i}').style.background='green'"
        else
            errors_present = true
            page.send :record, "$('rec#{i}').style.background='red'"
        end
        i=i+1
      end
      if not errors_present
          flash[:notice] = "#{record_count} records created."
          page.send :record, "window.location='/billing/new_flight_record';"
      else
        page.send :record, "Form.Element.enable('commit');"
      end     
    end
  end
end


# Called by AJAX code when a value is entered in instructor field in
# flight billing entry form. Updates the value of the instructor_rate box.
def set_instructor
  instructor = User.find_by_id(params[:instructor])
  if not instructor.nil?
    @rate = instructor.hourly_rate 
    render :update do |page|   
        page.send :record, "$('instructor_rate#{params[:rec_id]}').value='#{@rate}'" 
        page.visual_effect :highlight , "instructor_rate#{params[:rec_id]}", {:restorecolor => "'#ffffff'"}
     end 
  end   

end

# Called by AJAX code when a value is entered in aircraft field in
# flight billing entry form. Updates the aircraft_rate box.
def set_aircraft
    aircraft = Aircraft.find_by_id(params[:aircraft])
    if not aircraft.nil?
      @rate = aircraft.hourly_rate 
      render :update do |page|   
         page.send :record, "$('aircraft_rate1').value='#{@rate}'" 
         page.visual_effect :highlight , 'aircraft_rate1', {:restorecolor => "'#ffffff'"}
      end 
    end   
      
end

# Called by AJAX code when values are modified in the
# flight billing entry form. Updates the value of amount_charged boxes.
def record_modified
  i = 1
  render :update do |page|   
    while params["rec#{i}"]!=nil
      arate = params["rec#{i}"][:aircraft_rate]
      hstart = params["rec#{i}"][:hobbs_start]
      hend = params["rec#{i}"][:hobbs_end]
      irate = params["rec#{i}"][:instructor_rate] || 0
      if arate.nil? || arate=='' || hstart.nil? || hstart == '' || hend.nil? || hend=='' 
        i=i+1
        next 
      end 
      charge = ((hend.to_f-hstart.to_f)%100) * (irate.to_f+arate.to_f)
      charge = (charge*100).round / 100.0
      page.send :record, "$('charge_amount"+i.to_s+"').value='#{charge}'" 
      page.visual_effect :highlight , 'charge_amount'+i.to_s, {:restorecolor => "'#ffffff'"}    
      i=i+1
    end
  end
    
end

# page for editing per-hour rates for instructors and aircraft
def edit_rates
  return unless has_permission :can_do_billing
  @page_title = 'Edit Aircraft and Instructor Hourly Rates'
  @instructors = Group.users_in_group('instructor')
  @aircrafts = Aircraft.find(:all,:conditions=>['deleted = false'],:order=>"identifier")
  @offices = Office.find :all
  @instructors.sort!{|a,b| a.first_names<=>b.first_names}
  @aircrafts.sort!{|a,b| a.type.type_name<=>b.type.type_name}
  case request.method
  when :post
    @error_saving = false
    params[:aircraft].each{|k,v|
      begin
        aircraft = Aircraft.find(k)
        aircraft.hourly_rate = v
        aircraft.save
      rescue
         @error_saving = true 
      end
    }
    params[:instructors].each{|k,v|
      begin
        instructor = User.find(k)
        instructor.hourly_rate = v
        instructor.save
      rescue 
        @error_saving = true 
      end
    }
    if @error_saving
      flash[:warning] = 'Error saving some of the values'
    else
      flash[:notice] = 'Updated'
    end  
    redirect_to :back
  end
end

# admin report displaying aircraft usage and revenue statistics
def admin_report
  return unless has_permission :can_do_billing
  @page_title = "Billing Report"
  @earliest = FlightRecord.find(:first, :order => "flight_date")
  if @earliest.nil? or  params[:date].nil? then return end

  @start_date = Time.local(params[:date][:year].to_i, params[:date][:month].to_i)
  @end_date = @start_date.months_since params[:date][:range].to_i 
  @page_title = "Billing Report for " + @start_date.strftime("%b %Y") + " to " + @end_date.strftime("%b %Y")

  @solo = FlightRecord.sum('hobbs_end-hobbs_start',:group=>:aircraft,
    :conditions=>['aircraft_id is not NULL and instructor_id is NULL and flight_date>=? and flight_date<?',@start_date,@end_date])
  @duo = FlightRecord.sum('hobbs_end-hobbs_start',:group=>:aircraft,
    :conditions=>['aircraft_id is not NULL and instructor_id is not NULL and flight_date>=? and flight_date<?',@start_date,@end_date])
  @charges = FlightRecord.sum('charge_amount',:group=>:aircraft,
    :conditions=>['aircraft_id is not NULL and flight_date>=? and flight_date<?',@start_date,@end_date])
  @aircrafts = Aircraft.find(:all,:conditions=>['deleted=false'],:order=>'identifier')
end

# student report showing billing transactions with running totals
def student_report
  @user_id = params[:user].nil? ? current_user.id : params[:user]
  return unless current_user.id.to_s == @user_id.to_s || has_permission(:can_do_billing) 
  @pages, @charges = paginate :billing_charges, :conditions=>["user_id = ?",@user_id],:order=>'created_at desc', :per_page => 20
  @user = User.find(@user_id)
  @page_title = "Billing Charges for #{@user.full_name}"
end
# 
# private
# 
# def parse_user val
#    if val=='' or val.nil?
#      return nil
#    elsif val[0..0]=='['
#      user_id = val.split(']')[0][1..-1]
#      return User.find(user_id)
#    end
# end
# 
# def parse_aircraft val
#   if val=='' or val.nil?
#       return nil
#    elsif val.split(',').size>1
#      aircraft_id = val.split(',')[1].strip
#      return Aircraft.find_by_identifier(aircraft_id)
#    end
#   return nil
# end


end
