class Office < ActiveRecord::Base

  def self.first_office
    return Office.find :first,:order=>'name'
  end
end
