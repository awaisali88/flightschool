####################################################
#
# profile_controller.rb
# @authors levpopov@mit.edu, bdglide@mit.edu
# Controllers for viewing and editing user profile
# information, as well as for searching user directory
#
####################################################

class ProfileController < ApplicationController

before_filter :login_required
before_filter :force_single_column_layout


#views a user's profile as well as unapproved profile changes with an option to approve the changes
def view
  user_id = params[:id].nil? ? current_user.id.to_s : params[:id]
  @user = User.find_by_id(user_id)
  @page_title = @user.full_name  
  @full_profile = (can_edit_any_user_info? or (user_id == current_user.id.to_s))
  
  @posts = ForumPost.find(:all,:conditions=>["created_by = ?",@user.id],:order=>'created_at desc')
  @reservations_total = Reservation.count(:conditions=>["created_by=?",@user.id])
  @reservations_noncanceled = Reservation.count(:conditions=>["created_by=? and status!='canceled'",@user.id])
  @reservations_month = Reservation.count(:conditions=>["created_by=? and time_start>? and time_start<?",@user.id,Time.now.months_ago(1),Time.now])
  @balance = BillingCharge.find(:first,:conditions=>["user_id = ?",@user.id],:order=>"id desc")
  @balance = @balance.nil? ? 0 : @balance.running_total
  @balance_avg = BillingCharge.average(:running_total,:conditions=>['user_id=? and created_at>? and created_at<?',@user.id,Time.now.months_ago(1),Time.now])
  @transaction_count = BillingCharge.count(:conditions=>['user_id=? and created_at>? and created_at<?',@user.id,Time.now.months_ago(1),Time.now])

  @charges = BillingCharge.find :all, :conditions=>["user_id = ?",@user_id],:order=>'created_at desc', :limit => 20
end

def edit
  user_id = params[:id].nil? ? current_user.id.to_s : params[:id]
  return unless (can_edit_any_user_info? or (user_id == current_user.id.to_s))  
  @user = User.find_by_id(user_id)
  
  @phones = @user.phone_numbers.clone
  while @phones.size < 3 do 
    @phones <<  UserPhoneNumber.new
  end
  @addresses = @user.addresses.clone
  while @addresses.size < 3 do 
    @addresses <<  UserAddress.new
  end
  @groups = Group.find :all, :order=>'group_name desc'
  @user_groups = @user.all_groups.map{|g| g['id'].to_s}
  @user_unapproved_groups = @user.unapproved_groups.map{|g| g['id'].to_s}
  @certificates = UserCertificate.certificate_categories.map{|pair| pair[1]}
  @user_certificates = @user.all_certificates
  
  @page_title = 'Edit User Profile for '+@user.full_name

  if request.method==:post
    @user.update_attributes(params[:user])
    #save the phone numbers
    (0..2).each{|i|
      @phones[i].user = @user
      if params[:phone]["#{i}"]['phone_number']==nil or params[:phone]["#{i}"]['phone_number'].strip==""
        if not @phones[i].new_record?
          @phones[i].destroy
          @phones[i]=UserPhoneNumber.new
        end 
      else
        @phones[i].update_attributes(params[:phone]["#{i}"])  
      end
    }
    #save the addresses
    (0..1).each{|i|
      empty = true
      params[:address]["#{i}"].each_pair{|k,v| if v!=nil and v.strip !="" then empty=false end}
      if empty
        if not @addresses[i].new_record?
          @addresses[i].destroy
          @addresses[i] = UserAddress.new
        end
      else
        @addresses[i].user = @user
        @addresses[i].update_attributes(params[:address]["#{i}"])
      end
    }
    #update group memberships
    @groups.each{|group|
      if params[:groups].nil? or params[:groups]["#{group.id}"].nil?
        @user.remove_group group
      else
        @user.add_group group
      end  
    }
    @user_groups = @user.all_groups.map{|g| g['id'].to_s}
    @user_unapproved_groups = @user.unapproved_groups.map{|g| g['id'].to_s}
    
    #save certificates
    @certificates.each{|certificate|
      cert = UserCertificate.find :first, :conditions=>['user_id=? and certificate_category=?',@user.id,certificate]
      if params[:has_certificate].nil? or params[:has_certificate][certificate].nil?
        cert.destroy unless cert.nil?
      else
        if cert.nil? 
          cert = UserCertificate.new 
          cert.certificate_category = certificate
          cert.user = @user
        end
       cert.update_attributes(params[:certificate][certificate])
      end  
    }        
  end
  @certificates = UserCertificate.certificate_categories.map{|pair| pair[1]}
  @user_certificates = @user.all_certificates
  
end

def set_portrait
  return unless (can_edit_any_user_info? or (params[:user] == current_user.id.to_s))  
  begin
    user = User.find_by_id params[:user]
    image = Image.new(params[:image])
    user.images<< image
    user.portrait = image
    user.save
    flash[:notice] = "Portrait saved"
  rescue
    flash[:warning] = "Upload failed"
  end
  redirect_to :back
end

#form to edit user's profile information including fields of a variable number (address, etc)
# on post changes select attributes of extra_user_info
# def edit
#   @user_id = params[:profile_id].nil? ? current_user.id.to_s : params[:profile_id]
#   begin
#   if (can_edit_any_user_info? or (@user_id == current_user.id.to_s))
#     @profile_user = User.find_by_id(@user_id)
#     session[:profile_user] = @profile_user
#     @extra_info = @profile_user.extra_user_info || ExtraUserInfo.new  
#         if @is_admin
#       @groups = {}
#       Group.find_all.map{|group| @groups[group.id]=group}
#       @unapproved_groups = ""
#       un_groups = UserGroupLink.find(:all, :conditions => ["user_id = ? AND approved = 'false'",@profile_user.id])
#       first = true
#       un_groups.each{|grp|
#         if first
#           @unapproved_groups = @groups[grp.group_id].group_name
#           @not_approved = true
#           @profile_not_approved = true
#           first = false
#         else
#           @unapproved_groups = @unapproved_groups + ", " + @groups[grp.group_id].group_name
#           @not_approved = true
#           @profile_not_approved = true
#         end
#       }
#       @unapproved_certificates = ""
#       un_certificates = UserCertificate.find(:all, :conditions => ["user_id = ?  AND approved = 'false'",@profile_user.id])
#       first = true
#       un_certificates.each{|crt|
#         ratings = ""
#         if crt.airplane_sel_rating
#           ratings = ratings + "Airplane SEL "
#         end
#         if crt.airplane_mel_rating
#           ratings = ratings + "Airplane MEL "
#         end
#         if crt.helicopter_rating
#           ratings = ratings + "Helicopter "
#         end
#         if crt.instrument_rating
#           ratings = ratings + "Instrument "
#         end
#         if first
#           @unapproved_certificates = crt.certificate_category + " " + ratings
#           @not_approved = true
#           @cert_not_approved = true
#           first = false
#         else
#           @unapproved_certificates = @unapproved_certificates + "<br>" + crt.certificate_category + " " + ratings
#           @not_approved = true
#           @cert_not_approved = true
#         end
#       }
#       
#     end   
#     case request.method
#     when :get
#       @page_title = @profile_user.full_name + ': Edit Profile'
#     when :post
#       params_hash = params[:extra_info]
#       @fail = false
#       if not validate_date params_hash,'birthdate','Birthday' then return
#       elsif not validate_date params_hash,'faa_physical_date','FAA Physical Date' then return 
#       elsif not validate_date params_hash,'last_biennial_or_certificate_date','Last Biennial or Certificate Date' then return
#       else
#       @extra_info.user_id = @user_id
#       @extra_info_temp = ExtraUserInfo.new
#       fill_from_params(@extra_info_temp,params[:extra_info])
#       if @extra_info_temp.birthdate.nil?
#         	flash[:warning] = "Please enter a birthdate."
#             redirect_to :back
#       else
#       if !(@extra_info_temp.birthdate == @extra_info.birthdate)
#         @extra_info.birthdate_approved = false
#       end
#       if !(@extra_info_temp.faa_physical_date == @extra_info.faa_physical_date)
#         @extra_info.physical_approved = false
#       end
#       fill_from_params(@extra_info,params[:extra_info])
#       @extra_info.save
#       @profile_user.office = params[:profile_user][:office]
#       @profile_user.save
#       redirect_to :action => 'view', :profile_id => @profile_user.id
#     end  
#     end
#     end
#   else
#   	flash[:warning] = "You do not have permissions to edit this user's profile."
#     redirect_to :back
#   end
# #  rescue
# # 	flash[:warning] = "Error while trying to edit user profile."
# #    go_back
#   end
# end

# # renders a form to add a new item
# def new_item
#     set_item_type
#     item = @item_type.new
#     render :update do |page| 
#       page.replace_html('add_new_'+params[:item_type], 
#           :partial => params[:item_type], :locals => {
#                                   :edit => true,
#                                   :item => item
#                                                    }) 
#       page.visual_effect :highlight, 'add_new_'+params[:item_type]
#     end 
# end
# 
# # renders a form to add a new group
# def new_group
#     group_link = UserGroupLink.new
#     render :update do |page| 
#       page.replace_html('add_new_group_link', 
#         :partial => 'new_group', :locals => {
#                                   :group_link => group_link
#                                                    }) 
#       page.visual_effect :highlight, 'add_new_group_link'
#     end 
# end
# 
# # removes form for adding new item
# def cancel_new_item
#     render :update do |page| 
#       page.replace_html('add_new_'+params[:item_type], 
#         :partial => 'new_item_link', :locals => {
#                                   :item_type => params[:item_type],
#                                                   }) 
#       page.visual_effect :highlight, 'add_new_'+params[:item_type]
#     end 
# end
# 
# #removes form for adding new group
# def cancel_new_group
#     render :update do |page| 
#       page.replace_html('add_new_group_link', 
#         :partial => 'new_group_link') 
#       page.visual_effect :highlight, 'add_new_group_link'
#     end 
# end
# 
# # renders for for editing a given item
# def edit_item
#     set_item_type
#     item = @item_type.find_by_id(params[:item_id])
#     #render_text("Testing")
#     #render :partial => params[:item_type], :edit => true, :item => item
#     render :update do |page| 
#       page.replace_html(params[:item_type]+params[:item_id], 
#         :partial => params[:item_type], :locals => {
#                                   :edit => true,
#                                   :item => item
#                                                    }) 
#       page.visual_effect :highlight, params[:item_type]+params[:item_id]
#     end 
# end
# 
# # cancels edit item form
# def cancel_edit_item
#     set_item_type
#     item = @item_type.find_by_id(params[:item_id])
#     render :update do |page| 
#       page.replace_html(params[:item_type]+params[:item_id], 
#         :partial => 'edit_item_link', :locals => {
#                                   :item_type => params[:item_type],
#                                   :item => item
#                                                    }) 
#       page.visual_effect :highlight, params[:item_type]+params[:item_id]
#     end 
# end
# 
# # saves specified group link and renders new group link
# def save_new_group_link
#   user_id = session[:profile_user].id
#   params_hash = params[:item]
#   group = Group.find_by_group_name(params_hash[:group_name])
#   same_link = UserGroupLink.find(:first, :conditions => ["user_id = ? AND group_id = ?",user_id,group.id])
#   if !(same_link.nil?)
#     flash[:warning] = "User already a member of that group"
#     return
#   end
#   link = UserGroupLink.new
#   link.user_id = user_id
#   link.group_id = group.id
#   link.approved = 'false'
#   if link.save
#      render :update do |page| 
#         page.insert_html(:bottom,'group_list', 
#             :partial => 'edit_group_link_wrapper', :locals => {
#                                   :group_link => link
#                                                    }) 
#         page.replace_html('add_new_group_link', :partial => 'new_group_link') 
#         page.visual_effect :highlight, 'group_link'+link.id.to_s
#     end
#   end
# end
# 
# # commits new item and renders it
# def save_new_item
#   set_item_type
#   if params[:item_id].nil?
#     item = @item_type.new
#     item.user_id = session[:profile_user].id
#   else
#     item = @item_type.find_by_id(params[:item_id])    
#   end
#   if params[:item_type] == 'certificate'
#     @item_hash = params[:item]
#     if item.id.nil?
#     same_cert = UserCertificate.find(:first, :conditions => ["user_id = ? AND certificate_category = ?",session[:profile_user].id,@item_hash[:certificate_category]])
#     if !(same_cert.nil?)
#       flash[:warning] = "User already has that certificate"
#       return
#     end
#     else
#     same_cert = UserCertificate.find(:first, :conditions => ["user_id = ? AND certificate_category = ? AND id <> ?",session[:profile_user].id,@item_hash[:certificate_category],item.id])
#     if !(same_cert.nil?)
#       flash[:warning] = "User already has that certificate"
#       return
#     end
#     end
# 
#   end
#   
#   if item.update_attributes(params[:item])
#   if params[:item_type] == 'certificate'
#     item.approved = false
#     item.save
#   end
#     if not params[:item_id].nil?
#       render :update do |page| 
#         page.replace_html(params[:item_type]+params[:item_id], 
#           :partial => 'edit_item_link', :locals => {
#                                   :item_type => params[:item_type],
#                                   :item => item
#                                                    }) 
#         page.visual_effect :highlight, params[:item_type]+params[:item_id]
#       end 
#     else
#     
#       render :update do |page| 
#         page.insert_html(:bottom,params[:item_type]+'_list', 
#           :partial => 'edit_item_link_wrapper', :locals => {
#                                   :item_type => params[:item_type],
#                                   :item => item
#                                                    }) 
#         page.replace_html('add_new_'+params[:item_type], 
#             :partial => 'new_item_link', :locals => {
#                                   :item_type => params[:item_type],
#                                                   }) 
#         page.visual_effect :highlight, params[:item_type]+item.id.to_s
#       end 
#     end
#     
#   end
# end
# 
# # deletes a given item from database and removes representation from page
# def delete_item
#    set_item_type
#    item = @item_type.find_by_id(params[:item_id])    
#    if item.destroy
#       render :update do |page| 
#         page.replace_html(params[:item_type]+params[:item_id], '')
#       end 
#    end
# end
# 
# # deletes a group link from database and removes representation from page
# def delete_group_link
#    group_link = UserGroupLink.find_by_id(params[:group_link_id])    
#    if group_link.destroy
#       render :update do |page| 
#         page.replace_html('group_link'+params[:group_link_id], '')
#       end 
#    end
# end
# 
# # no longer used
# def edit_form
# 
#   return if set_item_type
#   @user_id = params[:profile_id].nil? ? current_user.id.to_s : params[:profile_id]
#   @item_id = params[:item_id]
#   
#   @div_name = params[:div_name]
#   #begin
#   if (can_edit_any_user_info? or (@user_id == current_user.id.to_s))
#     @new_entry = false
#     if !(@item_type.find_by_id(@item_id))
#       @new_entry = true
#     else
#       @real_div = params[:real_div]
#     end
#     @item = @item_type.find_by_id(@item_id) || @item_type.new  
#     @item_t = params[:item_type]
#     render(:partial => @edit_partial)
#   else
#   	flash[:warning] = "You do not have permissions to edit this user's profile."
#     redirect_to :back
#   end
#   #rescue
#  #	flash[:warning] = "Error while trying to edit user profile."
#   #  go_back
#   #end
# end

# 
# 

# 
# # sets users email to approved
# def verify_email
#   @profile_user = User.find_by_id(params[:profile_id])
#   @profile_user.email_verified = true
#   @profile_user.save
#   redirect_to :action => params[:direct_to], :profile_id => params[:profile_id]
# end
# 
# # approves all specified unapproved profile aspects
# def approve_profile
#   @profile_user = User.find_by_id(params[:profile_id])
#   @extra_info = @profile_user.extra_user_info 
#   if params[:approve_groups]=='true'
#     un_groups = UserGroupLink.find(:all, :conditions => ["user_id = ? AND approved = 'false'",@profile_user.id])
#     un_groups.each{|grp|
#           grp.approved = true
#           grp.save
#     }
#   end
#   if params[:approve_certificates]=='true'
#     un_certificates = UserCertificate.find(:all, :conditions => ["user_id = ?  AND approved = 'false'",@profile_user.id])
#     un_certificates.each{|crt|
#           crt.approved = true
#           crt.save
#     }
#   end
#   if !(@extra_info.nil?)
#   if params[:approve_birthdate]=='true'
#     @extra_info.birthdate_approved = true
#   end
#   if params[:approve_physical]=='true'
#     @extra_info.physical_approved = true
#   end
#     @extra_info.save
#   end
#   redirect_to :action => params[:direct_to], :profile_id => params[:profile_id]
# end
# 
# # sets given user's account_suspended to true
# def suspend_user
#   @profile_user = User.find_by_id(params[:profile_id])
#   @profile_user.account_suspended = true
#   @profile_user.save
#   redirect_to :action => params[:direct_to], :profile_id => params[:profile_id]
# end
# 
# # sets given user's account_suspended to false
# def unsuspend_user
#   @profile_user = User.find_by_id(params[:profile_id])
#   @profile_user.account_suspended = false
#   @profile_user.save
#   redirect_to :action => params[:direct_to], :profile_id => params[:profile_id]
# end
# 
# protected
# 
# 
# #helper for setting item type to be used later for processing
# def set_item_type
# 	case params[:item_type]
# 		when 'phone'
# 			@item_type = UserPhoneNumber
# 		when 'address'
# 			@item_type = UserAddress
# 		when 'creditcard'
# 			@item_type = UserCreditCard
# 		when 'certificate'
# 			@item_type = UserCertificate
# 			@valid_types = ['private','instrument','commercial','atp','instructor']
# 		when 'screenname'
# 			@item_type = UserScreenname
# 			@services = ['aol','yahoo','google','msn','icq','skype']
# 	end
# 	return false
# end
# 
# #utility method for filling in structures from POST parameters
# def fill_from_params(rec,par)
#      rec.attributes = par
# end
# 
# # validates date format
#  def validate_date hash,name,human_name
#      begin       
#        if hash[name+'(1i)']==""  && hash[name+'(2i)']==""  && hash[name+'(3i)'] then return true end
#        d = Date.new(hash[name+'(1i)'].to_i,hash[name+'(2i)'].to_i,hash[name+'(3i)'].to_i) 
#        return true 
#      rescue
#          flash[:warning] = "Invalid #{human_name}."
#          redirect_to :back      
#          return false
#      end
#  end
#     
  
end
