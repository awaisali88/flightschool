class MaintenanceDate < ActiveRecord::Base

  belongs_to :aircraft,
     :class_name => 'Aircraft',
     :foreign_key => 'aircraft_id'

end
