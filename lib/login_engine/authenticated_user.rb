require 'digest/sha1'

# this model expects a certain database layout and its based on the name/login pattern. 

module LoginEngine
  module AuthenticatedUser

    def self.included(base)
      base.class_eval do

        # use the table name given
        set_table_name LoginEngine.config(:user_table)

        attr_accessor :new_password
      
        validates_presence_of :email, :on => :save
        validates_uniqueness_of :email, :on => :save
   
	validates_presence_of :first_names, :on => :create
	validates_presence_of :last_name, :on => :create
    
        validates_presence_of :password, :if => :validate_password?
        validates_confirmation_of :password, :if => :validate_password?
        validates_length_of :password, { :minimum => 5, :if => :validate_password? }
        validates_length_of :password, { :maximum => 40, :if => :validate_password? }
  
        protected 
      
        attr_accessor :password, :password_confirmation
      
        after_save '@new_password = false'
        after_validation :crypt_password
      
      end
      base.extend(ClassMethods)
    end
    
    module ClassMethods
    
      def authenticate(email, pass)
	u = find(:first, :conditions => ["email = ? AND email_verified = TRUE", email])
        return nil if u.nil?
        find(:first, :conditions => ["email = ? AND salted_password = ? AND email_verified = TRUE AND account_suspended = FALSE", email, AuthenticatedUser.salted_password(u.salt, AuthenticatedUser.hashed(pass))])
      end

      def authenticate_by_token(id, token)
        # Allow logins for deleted accounts, but only via this method (and
        # not the regular authenticate call)
        u = find(:first, :conditions => ["id = ? AND security_token = ?", id, token])
        return nil if u.nil? or u.token_expired?
        return nil if false == u.update_expiry
        u
      end
      
    end
  

    protected
    
      def self.hashed(str)
        # check if a salt has been set...
        if LoginEngine.config(:salt) == nil
          raise "You must define a :salt value in the configuration for the LoginEngine module."
        end
  
        return Digest::SHA1.hexdigest("#{LoginEngine.config(:salt)}--#{str}--}")[0..39]
      end
    
      def self.salted_password(salt, hashed_password)
        hashed(salt + hashed_password)
      end
    
    public
  
    # hmmm, how does this interact with the developer's own User model initialize?
    # We would have to *insist* that the User.initialize method called 'super'
    #
    def initialize(attributes = nil)
      super
      @new_password = false
    end

    def token_expired?
      self.security_token and self.token_expiry and (Time.now > self.token_expiry)
    end

    def update_expiry
      write_attribute('token_expiry', [self.token_expiry, Time.at(Time.now.to_i + 600 * 1000)].min)
      write_attribute('authenticated_by_token', true)
      write_attribute("email_verified", TRUE)
      update_without_callbacks
    end

    def generate_security_token(hours = nil)
      if not hours.nil? or self.security_token.nil? or self.token_expiry.nil? or 
          (Time.now.to_i + token_lifetime / 2) >= self.token_expiry.to_i
        return new_security_token(hours)
      else
        return self.security_token
      end
    end

    def change_password(pass, confirm = nil)
      self.password = pass
      self.password_confirmation = confirm.nil? ? pass : confirm
      @new_password = true
    end
    
    protected

    def validate_password?
      @new_password
    end


    def crypt_password
      if @new_password
        write_attribute("salt", AuthenticatedUser.hashed("salt-#{Time.now}"))
        write_attribute("salted_password", AuthenticatedUser.salted_password(salt, AuthenticatedUser.hashed(@password)))
      end
    end

    def new_security_token(hours = nil)
      write_attribute('security_token', AuthenticatedUser.hashed(self.salted_password + Time.now.to_i.to_s + rand.to_s))
      write_attribute('token_expiry', Time.at(Time.now.to_i + token_lifetime(hours)))
      update_without_callbacks
      return self.security_token
    end

    def token_lifetime(hours = nil)
      if hours.nil?
        LoginEngine.config(:security_token_life_hours) * 60 * 60
      else
        hours * 60 * 60
      end
    end

  end
end
  
