class Reservation < ActiveRecord::Base
 
 has_and_belongs_to_many :comments,
          :class_name => 'Document',
          :join_table => 'documents_reservations',
          :order => 'documents.id',
          :include => :creator

#deprecated, use pilot instead
 belongs_to :creator,
    :class_name => 'User',
    :foreign_key => 'created_by'

  belongs_to :pilot,
     :class_name => 'User',
     :foreign_key => 'created_by'

 
 belongs_to :instructor,
    :class_name => 'User',
    :foreign_key => 'instructor_id'
 
 belongs_to :aircraft,
    :class_name => 'Aircraft',
    :foreign_key => 'aircraft_id',
    :include => :type

  
  before_save :automatic_verification
  
def automatic_verification
  if self.reservation_type=='booking' and self.status == 'created' and self.violated_rules.size==0
    self.status = 'approved'
  end
end
    
def validate
  if status != 'canceled'
    if is_overlapping
     errors.add_to_base("Selected time period overlaps with existing reservations")
   
    end
    if time_start >= time_end
     errors.add_to_base("Invalid time range (start >= end)")
    end  
    if aircraft_id.nil? && instructor_id.nil?
     errors.add_to_base("Aircraft and instructor fields cannot both be empty")
    end  
  end
 
  if @override_acceptance_rules!=true and self.reservation_type=='booking'    
    rules = ReservationAcceptanceRule.find_all()
    exceptions = ReservationRulesException.find_all_by_user_id(self.pilot.id).map{|e| e.reservation_rule_id}
    rules.each{|rule|
      if exceptions.include? rule.id.to_i 
        next
      end
      case rule.name
      when 'advance_scheduling':
        if self.time_start > (Time.now+30.days)
          errors.add_to_base(rule.description)
        end
      when 'retroactive_scheduling':
        if self.time_start < Time.now
          errors.add_to_base(rule.description)
        end
      when '24_hours_advance':
        if self.time_start < Time.now + 24.hours
          errors.add_to_base(rule.description)          
        end
      end
    }
  end
end
    
def initialize(params=nil,pilot=nil)
  if not pilot.nil?
    params = {'reservation_type'=>'booking','status'=>'created','created_by'=>pilot.id}.merge(params)
  end
  super(params)
end


def self.changed_reservations
  find_by_sql(<<-"SQL"
              select rc.*, r.time_start as from, r.time_end as to, r.aircraft_id as aircraft,r.created_by as pilot,r.instructor_id as instructor,r.status as o_status 
              from reservations_changes r,reservations rc
              where r.sent=false and
              rc.id = r.id and
              r.reservation_type = 'booking';
              SQL
  )    
end 
 
def self.instructor_reservations instructor,from,to
  if instructor.nil?
    return []
  end
  #workaround for windows ruby bug not printing the time to spec
  from = from.strftime("%a %b %d %H:%M:%S %Y")
  to = to.strftime("%a %b %d %H:%M:%S %Y")
  
  find_by_sql(<<-"SQL"
              select * from reservations
              where instructor_id = #{instructor} and
              time_start <= '#{to}' and
              time_end >= '#{from}' and
              status != 'canceled'
              SQL
  )  
end

def self.aircraft_reservations aircraft,from,to
  if aircraft.nil?
    return []
  end
  #workaround for windows ruby bug
  from = from.strftime("%a %b %d %H:%M:%S %Y")
  to = to.strftime("%a %b %d %H:%M:%S %Y")

  find_by_sql(<<-"SQL"
              select * from reservations
              where aircraft_id = #{aircraft} and
              time_start <= '#{to}' and
              time_end >= '#{from}' and
              status != 'canceled'
              SQL
  )  
end

# if called the next reservation save will not include acceptance rules checking as part of validation
# this is useful for letting admins to make reservations not allowed for regular users
def override_acceptance_rules
  @override_acceptance_rules = true
end

def violated_rules
  if self.reservation_type !='booking' then return end
    
  rules = ReservationApprovalRule.find_all()
  violated_rules = []
  exceptions = ReservationRulesException.find_all_by_user_id(self.pilot.id).map{|e| e.reservation_rule_id}
  rules.each{|rule|
    if exceptions.include? rule.id.to_i 
      next
    end
        
    case rule.name
    when 'recent_physical':
      if self.instructor != nil then next end 
      if self.pilot.faa_physical_date.nil? or self.pilot.birthdate.nil? then 
        violated_rules<<rule 
        next
      end
      physical = Time.mktime(self.pilot.faa_physical_date.year,self.pilot.faa_physical_date.month) #truncate the date to month
      now = Time.mktime(Time.now.year,Time.now.month)
      if (self.pilot.birthdate>40.years.ago) ? (physical>now+2.years) : (physical>now+3.years) 
        violated_rules<<rule
      end
    when 'recent_certification':
      if self.instructor != nil then next end 
      if self.pilot.last_biennial_or_certificate_date.nil?  then 
        violated_rules<<rule 
        next
      end
      if self.pilot.last_biennial_or_certificate_date < (Time.now + 2.years )
        violated_rules<<rule
      end
    when 'approved_dates'
      if not (self.pilot.physical_approved and self.pilot.birthdate_approved and self.pilot.biennial_approved)
        violated_rules<<rule
      end
    end
  } 
  return violated_rules
end


def is_overlapping
   ins_r = Reservation.instructor_reservations instructor_id, time_start, time_end
   air_r = Reservation.aircraft_reservations aircraft_id, time_start, time_end
   (ins_r+air_r).each{|r|
      if r.id.to_i == id 
        next
      end
      if (r[:time_start]< time_end && r[:time_end]> time_start) ||
         (r[:time_start]== time_start) ||
         (r[:time_end]== time_end)
      return true
   end
   }
  return false 
end


def from
  t = self.time_start.hour
  if t==0 then return "12 am" end
  if t==12 then return "12 pm" end
  if t<12
    return "#{t} am"
  else 
    return "#{t-12} pm"
  end
end

def to
  t = self.time_end.hour
  if t==0 then return "12 am" end
  if t==12 then return "12 pm" end
  t = self.time_end.hour
  if t<12
    return "#{t} am"
  else 
    return "#{t-12} pm"
  end
end  

#def date
#  return Date.new(2005,6,28)
#end

def to_json
  attrs = @attributes.clone
  attrs.delete_if{|k,v| v.nil?} 
  attrs.merge!({'pilot'=>self.pilot.full_name_rev.gsub(' ','&nbsp;')}) unless self.pilot.nil?
  if(self.time_start != nil and self.time_end != nil)
    return attrs.merge({'start_date'=>time_start.to_date.to_s,
                        'end_date'=>time_end.to_date.to_s,
                        'start_int'=>time_start.to_i*1000,
                        'end_int'=>time_end.to_i*1000}).to_json
  else
    return attrs.to_json
  end
end

def start_date
  self.time_start ||= Time.now
  return self.time_start.to_date
end

def end_date
  self.time_end ||= Time.now
  return self.time_end.to_date
end


def date= date
  self.start_date = date
  self.end_date = date
end

def start_date= date
  self.time_start ||= Time.new
  d = date.to_date
  self.time_start = Time.local(d.year,d.month,d.day,self.time_start.hour)
end

def end_date= date
  self.time_end ||= Time.new
  d = date.to_date
  self.time_end = Time.local(d.year,d.month,d.day,self.time_end.hour)  
end


def from= t
  self.time_start ||= Time.new
  self.time_start = Time.local(self.time_start.year,self.time_start.month,self.time_start.day,convert_time(t))
end

def to= t
  self.time_end ||= Time.new
  self.time_end = Time.local(self.time_end.year,self.time_end.month,self.time_end.day,convert_time(t))
end

# def year= t 
#   self.time_start ||= Time.new
#   self.time_end ||= Time.new
# 
#   self.time_start = Time.local(t,self.time_start.month,self.time_start.day,self.time_start.hour)
#   self.time_end = Time.local(t,self.time_end.month,self.time_end.day,self.time_end.hour)  
# end
# 
# def month= t 
#   self.time_start ||= Time.new
#   self.time_end  ||= Time.new
# 
#   self.time_start = Time.local(self.time_start.year,t,self.time_start.day,self.time_start.hour)
#   self.time_end = Time.local(self.time_end.year,t,self.time_end.day,self.time_end.hour)  
# end
# 
# def day= t 
#   self.time_start ||= Time.new
#   self.time_end ||= Time.new
# 
#   self.time_start = Time.local(self.time_start.year,self.time_start.month,t,self.time_start.hour)
#   self.time_end = Time.local(self.time_end.year,self.time_end.month,t,self.time_end.hour)  
# end

def reservation_status
  case self.status
  when 'created': return  'Unapproved'
  when 'approved': return 'Approved'
  when 'canceled': return 'Canceled'
  end
end

def reservation_kind
  if self.reservation_type == 'booking'
    return 'Reservation'
  end
  return 'Block'
end

def reservation_summary
  return """<a href=\"#\" onclick=\"new Ajax.Updater('reservation_sidebar','/reservation/edit/?id=#{self.id}',{asynchronous:true, evalScripts:true})\">
	       #{self.time_start.strftime("%a&nbsp;%b&nbsp;%d, %I%p")}
	  	  #{self.instructor.nil? ? '' : ' w. '+self.instructor.first_names+'&nbsp;'+self.instructor.last_name[0..0]+'.'}
	  	  #{self.aircraft.nil? ? '' : ' ('+self.aircraft.identifier+')'}
	  	  </a>"""
end

private 

def convert_time t
  begin
    t = t.strip
    if t=='12 am' then return 0 end
    if t=='12 pm' then return 12 end
    case t[-2..-1].downcase
      when 'am'
         return t[0..-2].to_i
      when 'pm'
         return t[0..-2].to_i+12    
      else
        return nil
    end
  rescue
     return nil
  end
  
end

end
