    module BreadCrumbs
       def clean_bread_crumbs
        return if request.method == :post 
        return if params[:controller].to_s == 'image'
        return if params[:controller].to_s == 'search' && params[:action].to_s == 'searchbox'
        return if params[:controller].to_s == 'schedule' && params[:action].to_s == 'quickpick'
        
        session[:crumbs] ||= []
        if session[:crumbs].length > 0 
          
          if (session[:crumbs].last[:params][:controller] != params[:controller]) ||
              (params[:controller].to_s=='news' && params[:action].to_s=='index')
          
              session[:crumbs].clear       
              session[:crumbs]<<{:params => {:controller => 'news',:action=> 'index'},
                                 :title => 'Home'}
              return
          end
          
          i = 0
          session[:crumbs].each{|crumb|
              if crumb[:params][:controller]==params[:controller] &&
                 crumb[:params][:action]==params[:action]
                 session[:crumbs]=session[:crumbs].slice(0..(i-1))
                 return
              end              
              i=i+1
          }
          
          
        end
          
      end

       def bread_crumbs
          return if request.method == :post 
          return if params[:controller].to_s == 'image'
          return if params[:controller].to_s=='news' and params[:action].to_s=='index'
          return if params[:controller].to_s == 'search' && params[:action].to_s == 'searchbox'
          return if params[:controller].to_s == 'schedule' && params[:action].to_s == 'quickpick'
                   
          session[:crumbs] << {:params => params,
                                :title => (@page_title || '[Untitled]')}
#          if session[:crumbs].length > 3
#             session[:crumbs].delete_at 0
#          end
      end
      
      def go_back
        if session[:crumbs] and session[:crumbs].length > 0
          redirect_to session[:crumbs].last[:params]
        else
          redirect_to :controller => 'news', :action => 'index';
        end
      end
 
    end