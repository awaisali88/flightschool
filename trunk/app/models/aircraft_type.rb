class AircraftType < ActiveRecord::Base
  validates_numericality_of :sort_value,:only_integer => true

  def <=>(a)
    sort_value <=> a.sort_value
  end
  
  def self.types_at_office office
      sql_string = 
                   <<-"SQL"   
                       select aircraft_types.* from aircraft_types where 
                       (select count(*) from aircrafts where 
                           aircraft_types.id = aircrafts.aircraft_type 
                           and aircrafts.deleted=false 
                           and aircrafts.office=?) > 0;
                   SQL
      
      return find_by_sql([sql_string,office.id])
  end
  
  def self.active_types office=nil
    if office != nil
      return self.types_at_office office
    end
    return find_by_sql(
                        <<-"SQL"   
                             select aircraft_types.* from aircraft_types where 
                             (select count(*) from aircrafts where 
                                 aircraft_types.id = aircrafts.aircraft_type 
                                 and aircrafts.deleted=false) > 0;
                         SQL
                      )
  end

end
