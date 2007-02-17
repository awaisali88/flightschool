module ReservationHelper

  def reservation_editor_data
    aircrafts = Aircraft.find(:all,:conditions=>['deleted = false'],:include=>:type)
    instructors = Group.users_in_group('instructor')
    data = {}
    aircrafts.each{|a|
      o = a.current_office.name
      data[o] ||= {}
      data[o]['aircraft_types'] ||= {}
      data[o]['aircraft_types'][a.type.type_name] ||= []
      data[o]['aircraft_types'][a.type.type_name] << {:name=>a.identifier_and_equip,:id=>a.id}
    }
    
    data.each_pair{|office,hash|
      hash['aircraft_types'] ||={}
      hash['aircraft_types']['- None/Ground School -'] = [{:name=>'None',:id=>''}]
    }
    
    instructors.each{|i|
      o = i.current_office.name
      data[o] ||= {}
      data[o]['instructors'] ||= []
      data[o]['instructors'] << {:name=>i.full_name_rev,:id=> i.id}
    }
    data.sort
    return data.to_json
  end
    
    
  def options_for_aircrafts
    if @location.nil?
      aircrafts = Aircraft.find(:all ,  :conditions => ['deleted = false'],:include=>:type, :order => 'aircraft_type')
    else
      aircrafts = Aircraft.find(:all ,  :conditions => ['deleted = false and office = ?',@location],:include=>:type, :order => 'aircraft_type')
    end
    return aircrafts.map{|aircraft|
        [aircraft.type.type_name+'('+aircraft.type_equip+') ' + aircraft.identifier,aircraft.id]
    }
  end

  # def options_for_instructor instructors
  #   [['No Instructor',nil]]+instructors.map{|inst|
  #     [inst.first_names+' '+inst.last_name,inst.id.to_i]
  #   }   
  # end
  # 
  # def options_for_instructors office
  #   office ||= Office.first_office
  #   instructors = Group.users_in_group('instructor')
  #   instructors.each{|instructor|
  #     if instructor.office != office
  #       instructors.delete instructor
  #     end
  #   }
  #   return options_for_instructor(instructors)
  # end
  # 
  # 
  # def options_for_aircrafts office,type
  #   office ||= Office.first_office
  #   type ||= (AircraftType.active_types office)[0]
  #   aircrafts = Aircraft.find(:all ,  :conditions => ['deleted = false and office = ?',office.id],:include=>:type, :order => 'identifier')
  #   [['Ground School',nil]]+aircrafts.map{|aircraft|
  #       [aircraft.identifier_and_equip,aircraft.id]
  #   }
  # end
  # 
  # def options_for_aircraft_types office
  #   office ||= Office.first_office    
  #   types = AircraftType.active_types(office)
  #   return types.map{|type|
  #     [type.type_name,type.id.to_i]
  #   }  
  # end
  
  def options_for_time
    return  [['12 am',0]]+(1..11).map{|x| [x.to_s+' am',x]}+[['12 pm',12]]+(1..11).map{|x| [x.to_s+' pm',x+12]}
  end
  
end