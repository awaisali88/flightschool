class FileController < ApplicationController
  
  caches_page :get
  before_filter :login_required, :except=>[:get]
  before_filter :force_single_column_layout
  
  def list
    @page_title = 'Uploaded Files'
    @pages,@files = paginate :uploaded_file, :conditions=>['user_id = ?',current_user.id],:select=>'id,file_name,file_type',:order=>'id desc',:per_page=>25
  end
 
  def delete
    begin
      file = UploadedFile.find params[:id]
      return unless current_user.id.to_s == file.user_id.to_s || has_permission(:admin) 
      file.destroy
      flash[:notice] = 'File deleted.'
      expire_action :action => "get", :id => params[:id] 
    rescue
      flash[:warning] = 'Deletion failed.'
    end
    redirect_to :back
  end

  def save
    return unless has_permission(:admin) 
    file = UploadedFile.new(params[:file])
    file.user_id = current_user.id
    if file.save
      flash[:notice] = "File uploaded."
    else
      flash[:notice] = "Uploaded failed."
    end
    redirect_to :back
  end
  
  
  def get 
    file = UploadedFile.find_by_id params[:id]
    if file!=nil
        send_data(file.file_binary,
                  :filename => file.file_name,
                  :type => file.file_type,
                  :disposition => "inline")
    end
  end
  
end
