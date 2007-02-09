#####################################################################################
#
# StaticController implements the editing and viewing functionality of static content,
# which is viewable from '/content/'
#
# Authors:: Lev Popov levpopov@mit.edu
# 
#####################################################################################


class StaticController < ApplicationController

#before_filter :no_access, :except=>[:view,:view_index]
before_filter :force_single_column_layout
before_filter :login_required, :except=>[:view]


# main static content administration interface 
# presents a list of all static pages with controls for editing them
def list
  return unless has_permission :can_edit_site_content
  @page_title = 'Static Pages'
  @documents = StaticContent.find_by_school current_school
  
end

# page with form to create a new static page
def new
  return unless has_permission :can_post_news
  @page_title = 'Create New Static Page'
  @document = StaticContent.new
  if request.method == :post
    @document = StaticContent.new (params[:document],current_user,current_school)
    if @document.save
      flash[:notice] = 'Document was successfully created.'
      redirect_to :action => 'list'
    end
  end
end

# page to edit specified news article
def edit
  return unless has_permission :can_post_news
  @page_title = 'Edit Static Page'
  @document = StaticContent.find(params[:id])
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

def delete
  return unless has_permission :can_post_news
  begin
    document = StaticContent.find_by_id params[:id]
    document.destroy
    flash[:notice] = 'Document deleted.'
  rescue
    flash[:notice] = 'Deletion failed.'
  end
  redirect_to :back
end

# # Provides an interface by which to edit static content, as well as links to create new children
# # and edit existing children and parent of the given page.  Also has link to view given page
# def edit
#   return unless has_permission :can_edit_site_content
#   @page_title = 'Edit Static Page'
#   if(params[:document].nil?)
#     @document = Document.find(:first,:conditions =>["refers_to is null and document_type='static_page'"]) #root page
#   else
#     @document = Document.find_by_id(params[:document])
#   end
#   
#   @parents = []
#   p = @document.parent
#   while not p.nil?
#     @parents << p
#     p = p.parent
#   end 
#   
#   @children = Document.find(:all, :conditions => ["refers_to = ? and document_type='static_page'",@document.id])
#   @versions = @document.versions
#   session[:edit_document] = @document
# end

# Renders in HTML and Textile the given static page
def view
  @page = StaticContent.find(:first,:conditions =>["url_name=?",params[:url].join('/')]) 
  if @page == nil
    flash[:warning] = 'Sorry, the page you have requested does not exist.'
    redirect_to :back;
    return
  end
  @page_title = @page.one_line_summary
end


# #Gives interface to create new static page child of linking document
# def new
#   return unless has_permission :can_edit_site_content
#   @page_title = 'New Static Page'
# end
# 
# #Cancels creation process for new static page
# def cancel_new
# end
# 
# #Creates a new static page with given attributes with parent stored in session
# def create
#   return unless has_permission :can_edit_site_content
#   @doc = Document.new
#   @doc.refers_to =   session[:edit_document].id
#   @doc.document_type = 'static_page'
#   @doc.created_by = current_user
#   @doc.last_updated_by = current_user
#   @doc.mime_type = "text/textile"
#   @doc.one_line_summary = ""
#   @doc.body = ""
#   @doc.status = "approved"
#   @doc.url_name = params[:url_name]
#   @doc.save 
# end
# 
# # Saves new version of document with given attributes
# def save
#   return unless has_permission :can_edit_site_content
#   @document = Document.find(params[:id])
#   @document.last_updated_by = current_user 
#   if @document.update_attributes(params[:document])
#     flash[:notice] = 'Page was successfully updated.'
#     redirect_to :action => 'edit', :document => @document
#   else
#      render :action => 'edit'
#   end
# end

end
