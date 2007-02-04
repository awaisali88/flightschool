module SearchHelper

def static_page_link doc   
  parents = []
  p = doc.parent
  while not p.nil?
    parents << p
    p = p.parent
  end 
  url = "" 
  parents.reverse.each{|p| 
		url << "/"+p.url_name 	
  }
  url << "/"+doc.url_name 
  return  link_to( doc.one_line_summary,'/content'+url[5..url.length]) 
end 

end
