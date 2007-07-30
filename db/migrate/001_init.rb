require 'cms/document'
require 'cms/static_content'
require 'cms/forum'

class Init < ActiveRecord::Migration
  def self.up
    #load up the schema from .sql file
    f = File.new('db/init_schema.sql')
    execute f.read
    f.close
    
    #create groups
    admin_group = Group.new ({:group_name=>'admin',:group_type=>'role'})
    admin_group.save
    (Group.new ({:group_name=>'student',:group_type=>'role'})).save
    (Group.new ({:group_name=>'renter',:group_type=>'role'})).save
    (Group.new ({:group_name=>'instructor',:group_type=>'role'})).save
    (Group.new ({:group_name=>'former_instructor',:group_type=>'role'})).save
    (Group.new ({:group_name=>'aircraft_owner',:group_type=>'role'})).save
    
    #create the school
    school = School.new ({:name=>'Flight School',:root_document=>'0'})
    school.save
    
    #create the default school office
    office = Office.new ({:name=>'Primary Office',:zipcode=>'02139',:school_id=>school})
    office.save
    
    #create the admin user 
    admin = User.new
    admin.email = 'admin@yourflightschool.com'
    admin.first_names = 'Admin'
    admin.last_name = 'User'
    admin.change_password "password"
    admin.office = office
    admin.email_verified = true
    admin.save
    admin.add_group admin_group
    admin.approve_all_groups
    
    #create root CMS doc
    root_doc = StaticContent.new ({:url_name=>'root',:one_line_summary=>'root',:body=>'root'},admin)
    root_doc.save
    school.root_document = root_doc
    school.save
    
    #create the main page
    index = StaticContent.new ({:url_name=>'index',:one_line_summary=>'Welcome to FlightSchool',:body=>'Please edit this page throught the admin interface'},admin,school)
    index.save
    
    #create the forum
    forum = Forum.new 'general'
    forum.description = 'General Discussion'
    forum.created_by = admin
    forum.last_updated_by = admin
    forum.save
    
  end

  def self.down
  end
end
