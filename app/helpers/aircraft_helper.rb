module AircraftHelper

def options_for_aircraft_types
  types = AircraftType.find(:all)
  types.map{|type|
    [type.type_name,type.id.to_i]
  }  
end

end
