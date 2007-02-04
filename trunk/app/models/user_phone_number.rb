class UserPhoneNumber < ActiveRecord::Base
	belongs_to :user
	
	validates_presence_of :user_id
  validates_presence_of :phone_number, :on => :create
	
	validates_each :phone_number do |record, attr_name, value|
	     n_digits = value.scan(/[0-9]/).size
        valid_chars = (value =~ /^[+\/\-() 0-9]+$/)
        if !(n_digits > 5 && valid_chars)
          record.errors.add(attr_name, "is an invalid phone number, must contain at least 5 digits, only the following characters are allowed: 0-9/-()+")
        end
  end
			 
end
