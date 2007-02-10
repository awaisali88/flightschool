class User < ActiveRecord::Base
  include LoginEngine::AuthenticatedUser
  
#  validates_numericality_of :hourly_rate
  
  has_many :forum_posts,
            :class_name => 'ForumPost',
            :foreign_key => 'created_by'
    
  has_and_belongs_to_many  :approved_groups,
                            :class_name => 'Group',
                            :join_table => 'groups_users',
                            :foreign_key => 'user_id',
                            :association_foreign_key => 'group_id',        
                            :finder_sql =>  
                            <<-"SQL"
                            select groups.* from groups,groups_users
                            where groups_users.user_id = #{self.id} and 
                            groups.id = groups_users.group_id and 
                            groups_users.approved = true;
                            SQL

  has_and_belongs_to_many  :unapproved_groups,
                            :class_name => 'Group',
                            :join_table => 'groups_users',
                             :foreign_key => 'user_id',
                            :association_foreign_key => 'group_id',  
                            :finder_sql => 
                            <<-"SQL"
                            select groups.* from groups,groups_users
                            where groups_users.user_id = #{self.id} and 
                            groups.id = groups_users.group_id and 
                            groups_users.approved = false;
                            SQL
  
  has_many :images, :class_name=>'Image'
  belongs_to :portrait, :class_name=>'Image',:foreign_key=>'portrait_id'
  has_many :addresses, :class_name=>'UserAddress'
  has_many :phone_numbers, :class_name=>'UserPhoneNumber'
 
  #deprecated - user current_office instead
   belongs_to :default_office,
         :class_name => 'Office',
         :foreign_key => 'office'


   belongs_to :current_office,
         :class_name => 'Office',
         :foreign_key => 'office'

   validates_each :birthdate,:faa_physical_date,:last_biennial_or_certificate_date do |record, attr_name, value|
      val = record.send("#{attr_name}_before_type_cast")
      begin
        val.to_date unless (val.nil? or val.strip=="")
      rescue    
        record.errors.add(attr_name, "is not a valid date. Please clear the box if you don't want the date to be saved")
      end
   end



  def initials
   return first_names[0..0]+last_name[0..0]
  end    

  def full_name
    return first_names+' '+last_name
  end    

  def full_name_with_initials
    return first_names+' '+last_name+' '+self.initials
  end    
  
  def full_name_rev
      return last_name+", "+first_names
  end
  
  def full_name_link
    return "<a href=\"/profile/view/#{self.id}\">#{full_name.gsub(' ','&nbsp;')}</a>"
  end

  def full_name_rev_link
    return "<a href=\"/profile/view/#{self.id}\">#{full_name_rev.gsub(' ','&nbsp;')}</a>"
  end

  def short_name
    return "<a href=\"/profile/view/#{self.id}\">#{self.last_name},&nbsp;#{self.first_names[0..0]}</a>"
  end
    
  def full_name_with_id
    return id.to_s+'. '+first_names+' '+last_name
  end    
  
  def groups
    return approved_groups
  end
  
  def all_groups
       Group.find_by_sql( 
        <<-"SQL"   
          select groups.* from groups,groups_users
          where groups_users.user_id = #{id} and 
          groups.id = groups_users.group_id;
           SQL
      )
  end
 
  def approved_groups
      Group.find_by_sql( 
        <<-"SQL"   
          select groups.* from groups,groups_users
          where groups_users.user_id = #{id} and 
          groups.id = groups_users.group_id and
          groups_users.approved = true;
           SQL
      )
  end
  
  def unapproved_groups
       Group.find_by_sql( 
        <<-"SQL"   
          select groups.* from groups,groups_users
          where groups_users.user_id = #{id} and 
          groups.id = groups_users.group_id and
          groups_users.approved = false;
           SQL
      )
  end

  def approve_all_groups
    connection.execute("update groups_users set approved=true where user_id=#{id}")
  end
  
  def all_certificates
      UserCertificate.find :all,:conditions=>['user_id=?',id]
  end

  def unapproved_certificates
      UserCertificate.find :all,:conditions=>['user_id=? and approved=false',id]
  end

  def remove_group group
    connection.execute("delete from groups_users where user_id=#{id} and group_id=#{group.id}")
  end

  def add_group group
    if User.find_by_sql("select * from groups_users where user_id=#{id} and group_id=#{group.id}").size==0
      connection.execute("insert into groups_users values(default,#{id},#{group.id},false)")   
    end
  end
  
  def in_group? group
    return Group.find_by_sql(["""select * from groups,groups_users where
                                 groups_users.group_id=groups.id and 
                                 group_name=? and 
                                 groups_users.user_id=? and
                                 groups_users.approved=true""",group,self.id]).size>0
  end
  
  def birthdate=(date)
        if birthdate.to_s == date.to_s then return end
        write_attribute(:birthdate,date)
        @attributes['birthdate_approved'] = false
  end
  
  def faa_physical_date=(date)
        if faa_physical_date.to_s == date.to_s then return end
        write_attribute(:faa_physical_date,date)
        @attributes['physical_approved'] = false
  end
  
  def last_biennial_or_certificate_date=(date)
        if last_biennial_or_certificate_date.to_s == date.to_s then return end
        write_attribute(:last_biennial_or_certificate_date,date)
        @attributes['biennial_approved'] = false
  end
  
  def is_us_citizen=(val)
        if is_us_citizen.to_s == val.to_s then return end
        write_attribute(:is_us_citizen,val)
        @attributes['us_citizen_approved'] = false
  end
      
  def self.permanently_delete_user user_id
     ActiveRecord::Base.connection.execute <<-"SQL"
          begin;
          delete from groups_users where user_id = #{user_id};
          delete from user_addresses where user_id = #{user_id};
          delete from user_phone_numbers where user_id = #{user_id};
          delete from user_certificates where user_id = #{user_id};
          delete from images where user_id = #{user_id};
          delete from billing_charges where user_id = #{user_id};
          delete from reservation_rules_exceptions where user_id = #{user_id};
          delete from documents_reservations where (select count(*) from reservations r 
          where r.id = reservation_id and r.created_by=#{user_id}) > 0; 
          delete from documents_reservations where (select count(*) from reservations r 
          where r.id = reservation_id and r.instructor_id=#{user_id}) > 0; 
          delete from reservations where created_by = #{user_id};
          delete from reservations where instructor_id = #{user_id};
          delete from documents	where created_by = #{user_id};		
          delete from documents_audit	where created_by = #{user_id};		
          delete from documents	where last_updated_by = #{user_id};		
          delete from documents_audit	where last_updated_by = #{user_id};		
          delete from users where id = #{user_id};	
          commit;
          SQL
  end
  
  def self.active_users
    return User.find :all,:conditions=>'account_suspended=false'
  end
end

