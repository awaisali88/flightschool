class FlightRecord < BillingCharge
      
  validates_presence_of :flight_date
  before_save :compute_aircraft_params

  def validate
    if pilot.nil?
      errors.add_to_base 'Invalid pilot.'
    end
        
    if instructor_id==nil and aircraft_id==nil
      errors.add_to_base 'Insufficient information to create a record. Please specify either an aircraft or an instructor.'
    end
    
    if aircraft_id!=nil and aircraft_rate==nil
      errors.add_to_base 'Aircraft rate missing.'
    end

    if instructor_id!=nil and instructor_rate==nil
      errors.add_to_base 'Instructor rate missing.'
    end
    
    count = (hobbs_start.nil? ? 0 : 1) + (hobbs_end.nil? ? 0 : 1) + (tach_start.nil? ? 0 : 1) + (tach_end.nil? ? 0 : 1)
    if count>0 and count<4 
      errors.add_to_base 'Either all or none of the following must be specified: Hobbs Start, Hobbs End, Tach Start, Tach End'
    end
    
  end
  
  def compute_aircraft_params
    
    if aircraft==nil then return end
    hobbs = aircraft.hobbs.to_f  
    tach = aircraft.tach.to_f  

    hs = (hobbs/100).floor*100 + @attributes['hobbs_start'].to_f
    if (hs<hobbs) then hs = hs+100 end

    he = (hs/100).floor*100 + @attributes['hobbs_end'].to_f
    if (he< hs) then he = he+100 end

    ts = (tach/100).floor*100 + @attributes['tach_start'].to_f
    if (ts<tach) then ts = ts+100 end

    te = (ts/100).floor*100 + @attributes['tach_end'].to_f
    if (te<ts) then te = te+100 end

    @attributes['hobbs_start'] = hs
    @attributes['hobbs_end'] = he
    @attributes['tach_start'] = ts
    @attributes['tach_end'] = te
  end


  def initialize(params,aircraft,user)
     params.merge!({:aircraft_id=>aircraft})
     super(params,user)
  end
   
end