class UserAddress < ActiveRecord::Base
	belongs_to :user
  validates_presence_of :user_id
  validates_presence_of :address_line1
  validates_presence_of :city
  validates_presence_of :postal_code
  validates_presence_of :state_province
  
  def self.human_attribute_name attr_name
    case attr_name.to_sym
    when :postal_code: return 'Zip code'
    when :state_province: return 'State/Province'
    when :address_line1: return 'Address Line 1'  
    else self.superclass.human_attribute_name(attr_name)
    end
    
  end
end
