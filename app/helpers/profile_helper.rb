module ProfileHelper
  def get_items(type,user_id)
    return type.find_all_by_user_id(user_id)
  end
  
  def form_tab_tag tab_name
    '<div class="form_tab">'+
    '<div class="form_tab_title">'+
	'<a onclick="new Effect.toggle($(\''+tab_name.gsub(' ','').underscore+'\'),\'blind\',{duration:.1})">'+
	'&gt&gt '+ tab_name+'</a>'+
    '</div><div id="'+tab_name.gsub(' ','').underscore+'" class="form_tab_content" style="float:none;">'
  end
  
  def end_form_tab
    "</div></div>"
  end
  
end
