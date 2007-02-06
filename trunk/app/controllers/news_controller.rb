##############################################
#
# admin_controller.rb
# @authors Lev Popov levpopov@mit.edu 
# Implementation of news functionality allowing admins to post/edit news and users to read it
#
##############################################

class NewsController < ApplicationController
  
before_filter :force_single_column_layout, :except=>[:index]
  
  # page with paginated new stories  
  def index
    @page_title = user? ? 'Recent News' : 'Welcome'
    @news_pages, @news = paginate :news_article, :order_by => '-id',:per_page => 6,
            :conditions => ["status='approved'"]
  end

  #page with list of news stories
  def list
   return unless has_permission :can_post_news
    @page_title = 'Posted News'
    @document_pages, @documents = paginate :news_article, :order_by => '-id', :per_page => 25    
  end
  
  # changes status on specified news stories
  def update_status
    return unless has_permission :can_post_news
    return unless request.method == :post
    params.each_key{|k|
      if not k[/^status/].nil?
        doc = Document.find_by_id(k.gsub(/^status/,''))
        if doc.status != params[k]
          doc.status = params[k]
          doc.last_updated_by = current_user 
          doc.save
        end
      end
    }
    redirect_to :action => 'list'
  end

  # page with form to create a new news article
  def new
    return unless has_permission :can_post_news
    @page_title = 'Post New Article'
    @document = NewsArticle.new
    if request.method == :post
      @document = NewsArticle.new (params[:document],current_user)
      if @document.save
        flash[:notice] = 'Document was successfully created.'
        redirect_to :action => 'list'
      end
    end
  end
  
  # page to edit specified news article
  def edit
    return unless has_permission :can_post_news
    @page_title = 'Edit News Article'
    @document = NewsArticle.find(params[:id])
    if params[:version]!=nil
      @document = @document.get_version params[:version]
    end
    if request.method == :post
      @document.last_updated_by = current_user 
       if @document.update_attributes(params[:document])
         flash[:notice] = 'Document was successfully updated.'
       end
     end
     @versions = @document.versions
  end

end
