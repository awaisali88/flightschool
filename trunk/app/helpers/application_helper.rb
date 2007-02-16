# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
    include LoginEngine
    include PermissionsChecker
#    include BreadCrumbs
    include MultiSchool

def int_to_time t
   if t==0 then return "12 am" end
   if t==12 then return "12 pm" end
   if t<12
     return "#{t} am"
   else 
     return "#{t-12} pm"
   end
end

# returns the number of hours between local time zone and GMT
def offset_from_GMT()
  return (Time.local(2000)-Time.gm(2000))/1.hour
end
    
def isMSIE?()
  @request.env['HTTP_USER_AGENT'].downcase.index('msie')!=nil 
end

def isMSIE_mobile?()
  @request.env['HTTP_USER_AGENT'].downcase.index('windows ce')!=nil 
end

def isKHTML?()
  @request.env['HTTP_USER_AGENT'].downcase.index('khtml')!=nil 
end

def options_for_offices
  offices = Office.find(:all,:order=>'name')
  offices.map{|office|
    [office.name,office.id]
  }
end

def link_to_file(name, file, *args)
     if file[0] != ?/
        file = "#{@request.relative_url_root}/#{file}" 
     end
     link_to name, file, *args
end
   
def make_row *rest
  tag = "<tr>"
  rest.each{|r|
    tag += '<td>'+r+'</td>'
  }
  tag+="</tr>"    
  return tag
end   
 
 def text_date_field obj,obj_name,field,options={}
   return "<table cellpadding=\"0px\" cellspacing=\"0px\"><tr><td>#{text_field(obj_name,field,{:size=>'10'}.merge(options))}</td></tr>"+
          "<tr><td style=\"text-align:center\"><span class=\"field_hint\">(yyyy-mm-dd)</span></td></tr></table>"
 end
 
 def rounded_corners_box(heading,content)
  
 end
 
 
 def aircraft_string aircraft
   str = '['+"#{aircraft.id},'',"+
         "'#{aircraft.identifier}',"+
         "'<span class=\"informal\"><br/>#{aircraft.type.type_name}</span>'"+
         ']'
   return str
 end


 def user_string user
   str = '['+"#{user.id},'',"+
         "'#{user.full_name.gsub('\'','\\\'')} #{user.initials}',"+
         "'<span class=\"informal\"><br/>#{user.email}</span>'"+
         ']'
   return str
 end

 def user_array users  
   res = "["
   users.each{|u|
     res = res + user_string(u)+','
   }
   res[res.size-1]=']'
   return res
 end

 def aircraft_array aircrafts
   res = "["
   aircrafts.each{|a|
     s =  aircraft_string(a) + ","
     res = res + s
   }
   res[res.size-1]=']'
   return res
 end
 
 
      #  
      #      
      # def get_parent action
      #   home = 'news/index'
      #   case action
      #     when 'news/list' then return 'news/index'
      #     when 'news/edit' then return 'news/list' 
      #     when 'news/new' then return 'news/list' 
      # 
      #     when 'forum/index' then return home
      #     when 'forum/view' then return 'forum/index' 
      #     when 'forum/new' then return 'forum/index' 
      #   end
      #   return nil
      # end
      # 
      # def get_title action
      #   
      #   case action
      #     when 'news/list' then return 'Post News'
      #     when 'news/edit' then return 'Edit Article' 
      #     when 'news/new' then return 'New Article' 
      # 
      #     when 'forum/index' then return 'Forum'
      #     when 'forum/view' then return 'View Thread' 
      #     when 'forum/new' then return 'New Thread' 
      #   end
      # end 
 
     # def get_crumbs controller,action
     #    ret = []
     #    id = controller.to_s+'/'+action.to_s
     #    while not (p = get_parent(id)).nil?
     #      ret << {:link => p,:title => get_title(p)}
     #      id = p
     #    end
     #    return ret.reverse
     # end
     
end
