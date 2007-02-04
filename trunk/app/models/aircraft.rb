class Aircraft < ActiveRecord::Base

  belongs_to :type,
    :class_name => 'AircraftType',
    :foreign_key => 'aircraft_type'

 #deprecated - user current_office instead
  belongs_to :default_office,
        :class_name => 'Office',
        :foreign_key => 'office'


  belongs_to :current_office,
        :class_name => 'Office',
        :foreign_key => 'office'
        
  validates_numericality_of :hourly_rate
  
  validates_numericality_of :hobbs
  
  validates_numericality_of :tach
  
  def type_and_identifier
      return self.type.type_name+' '+self.identifier
  end
  
  def identifier_and_equip
    return self.identifier+'-'+self.type_equip
  end

end
