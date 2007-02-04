module ScheduleHelper

def options_for_instructor instructors
  [['No Instructor',nil]]+instructors.map{|inst|
    [inst.first_names+' '+inst.last_name,inst.id.to_i]
  }   
end

def options_for_instructors
  instructors = Group.users_in_group('instructor')
  if not @location.nil?
    instructors.each{|instructor|
      if instructor.office != @location
        instructors.delete instructor
      end
    }
  end
  return options_for_instructor(instructors)
end

def options_for_aircrafts
  if @location.nil?
    aircrafts = Aircraft.find(:all ,  :conditions => ['deleted = false'],:include=>:type, :order => 'aircraft_type')
  else
    aircrafts = Aircraft.find(:all ,  :conditions => ['deleted = false and office = ?',@location],:include=>:type, :order => 'aircraft_type')
  end
  [['No Aircraft/Ground School',nil]]+aircrafts.map{|aircraft|
      [aircraft.type.type_name+'('+aircraft.type_equip+') ' + aircraft.identifier,aircraft.id]
  }
end

def self.options_for_aircrafts
  if @location.nil?
     aircrafts = Aircraft.find(:all ,  :conditions => ['deleted = false'],:include=>:type, :order => 'aircraft_type')
   else
     aircrafts = Aircraft.find(:all ,  :conditions => ['deleted = false and office = ?',@location],:include=>:type, :order => 'aircraft_type')
   end
   [['No Aircraft/Ground School',nil]]+aircrafts.map{|aircraft|
       [aircraft.type.type_name+'('+aircraft.type_equip+') ' + aircraft.identifier,aircraft.id]
   }
end


def options_for_aircraft_types 
   aircrafts = Aircraft.find(:all, :conditions => ['deleted = false and office=?',current_user.office])
   types = {}
   aircrafts.each{|aircraft|
     types[aircraft.aircraft_type] = aircraft.type
   }

   types = types.map{|k,v| v}
   types.sort!{|a,b| a.sort_value <=> b.sort_value}.reverse!
 
   types.map{|type|
    [type.type_name,type.id.to_i]
  }  
end

def is_reserved reservations,year,month,day,hour
  time = Time.local(year,month,day,hour)
  reservations.each{|reservation|
   if reservation[:time_start]<=time && reservation[:time_end]>time
      return reservation
   end
  }
  return false
end



end
