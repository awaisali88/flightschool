ActionController::Routing::Routes.draw do |map|
  # Add your own custom routes here.
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Here's a sample route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"

 
  map.connect '', :controller => "main"
  
  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
#  map.connect ':controller/service.wsdl', :action => 'wsdl'

#  map.connect 'mobile/', :controller => "mobile/user", :action => 'login'
  
  # Handle static content
  map.connect 'content/*url', :controller => 'static', :action => 'view'

  # Override for components urls
#  map.connect ':component/:component_controller/:component_action/:id', :controller => 'component', :action=>'index'
  
  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
  
end
