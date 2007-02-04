class ScheduleSweeper < ActionController::Caching::Sweeper 
observe Reservation 

def after_create(article) 
  ActionController::Base.fragment_cache_store.delete_matched(/schedule/,nil)  
end 

def after_update(article) 
  ActionController::Base.fragment_cache_store.delete_matched(/schedule/,nil)  
end 

def after_destroy(article) 
  ActionController::Base.fragment_cache_store.delete_matched(/schedule/,nil)  
end 

end 
