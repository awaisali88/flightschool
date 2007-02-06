##############################################################################
#
# Controller with functionality for keeping track of aircraft maintenance
# schedules, allowing administrators to create maintenance counters that
# display how long until a particular aircraft will need to be taken
# out for service. The counters are stored in MaintenanceDate ActiveRecord
# instances.
# Adapted from scaffold code.
#
# Authors:: Lev Popov levpopov@mit.edu
#
##############################################################################
class ImageController < ApplicationController
  
  caches_page :thumb
  caches_page :show
  before_filter :login_required, :only=>[:list]
  before_filter :force_single_column_layout
  
  
  def list
    @page_title = 'Uploaded Images'
    @pages,@images = paginate :image, :conditions=>['user_id = ?',current_user.id],:select=>'id',:order=>'id desc',:per_page=>25
  end
  
  def links_list
    @pages,@images = paginate :image, :conditions=>['user_id = ?',current_user.id],:select=>'id',:order=>'id desc',:per_page=>5
    render :partial=>'links_list',:layout=>false
  end
  
  def delete
    begin
      image = Image.find params[:id]
      return unless current_user.id.to_s == image.user_id.to_s || has_permission(:admin) 
      users = User.find (:all, :conditions=>['portrait_id = ?',image.id])
      users.each{|u| 
        u.portrait = nil
        u.save
      }
      image.destroy
      flash[:notice] = 'Image deleted.'
      expire_action :action => "show", :id => params[:id] 
      expire_action :action => "thumb", :id => params[:id] 
    rescue
      flash[:warning] = 'Deletion failed.'
    end
    redirect_to :back
  end
  
  def pick_or_upload
    @image_id = params[:image_id]
    params[:id] = params[:image_id]
    render :partial => 'pick_image'
  end
  

  def popup
      @images = Image.find_by_sql('select id from images where user_id='+
        current_user.id.to_s)
      @image = Image.new
  
     render :update do |page| 
        page.send :record, 'position_overlay()'
        page.replace_html 'overlay', render(:partial =>'upload')
        page.visual_effect :appear , 'overlay', :duration => 0.3
     end 
  end
  
  def cancel_upload
     render :update do |page| 
        page.visual_effect :fade , 'overlay', :duration => 0.3
     end 
  
  end

  def upload_started
     render :update do |page| 
        page.visual_effect :appear , 'upload_notifier', :duration => 0.3
     end    
  end  

  def upload
      @images = Image.find_by_sql('select id from images where user_id='+
        current_user.id.to_s)
      @image = Image.new
 
     render :update do |page| 
        page.replace_html 'overlay', render(:partial =>'upload')
     end 
  end

  def pick_image
     render :update do |page| 
        page.visual_effect :fade , 'overlay', :duration => 0.3
        page.send :record, "update_document_body(" + params[:id]+");" 
        page.replace_html 'image_drop_area', render(:partial =>'image_link')
     end 
  
	
  end
  
  def upload_status
     if session[:upload_complete] == true
       session[:upload_complete] = false
       render :text => "Uploading... <script>document.uploadStatus.stop()</script>"
     else
        render :text => 'Uploading...'
     end  
      
  end

  def save
    session[:upload_complete] = true
    @image = Image.new(params[:image])
    @image.user_id = current_user.id
    @image.caption 
    if @image.save
      flash[:notice] = "Image uploaded"
    end
    redirect_to :back
#    render :text => 'upload'
  end
  
  
  def show 
    @image = Image.find_by_id params[:id]
    if @image.nil?
       @image = File.open(RAILS_ROOT+'/public/images/noimage.png').read
       @type = 'image/png'
    else
      @type = @image.image_type
      @image = @image.image_binary
    end
    send_data(@image,
              :filename => 'image'+(params[:id] || ''),
              :type => @type,
              :disposition => "inline")
  end

  def thumb
    
    image_id = params[:id] || -1
    @image = Image.find_by_sql(['select thumbnail,image_type from images where id=? limit 1',image_id.to_s])
    if @image.length==0
      @thumbnail = File.open(RAILS_ROOT+'/public/images/noimage.png').read
      @type = 'image/png'
    else 
      @thumbnail = @image[0].thumbnail
      @type =  @image[0].image_type
    end
    send_data(@thumbnail,
              :filename => 'thumb'+image_id.to_s,
              :type => @type,
              :disposition => "inline")
  end

end
