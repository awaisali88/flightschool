class UserCertificate < ActiveRecord::Base
	belongs_to :user
  validates_presence_of :user_id
  def self.certificate_categories
    return [["Private","Private"],["Instrument", "Instrument"],["Commercial", "Commercial"],
    ["Certified Flight Instructor", "CFI"],
    ["Certified Instrument Instructor", "CFII"],
    ["Airline Transport Pilot", "ATP"]]
  end

  def airplane_sel_rating=(val)
        if airplane_sel_rating.to_s == (val.to_s=='1' ? 'true' : 'false') then return end
        write_attribute(:airplane_sel_rating,val)
        @attributes['approved']=false
  end

  def airplane_mel_rating=(val)
        if airplane_mel_rating.to_s == (val.to_s=='1' ? 'true' : 'false') then return end
        write_attribute(:airplane_mel_rating,val)
        @attributes['approved']=false
  end

  def helicopter_rating=(val)
        if helicopter_rating.to_s == (val.to_s=='1' ? 'true' : 'false') then return end
        write_attribute(:helicopter_rating,val)
        @attributes['approved']=false
  end

  def instrument_rating=(val)
        if instrument_rating.to_s == (val.to_s=='1' ? 'true' : 'false') then return end
        write_attribute(:instrument_rating,val)
        @attributes['approved']=false
  end
  
end
