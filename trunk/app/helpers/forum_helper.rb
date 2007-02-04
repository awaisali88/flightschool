module ForumHelper
  # def find_posts_by_user(user)
  #   posts = Document.find(:all, :conditions => ["document_type = 'post' and created_by = ?", user.id])
  #   return posts.length
  # end
  # 
  # def is_admin?(user)
  #   user_id = params[:profile_id]
  #   group = Group.find_by_group_name("admin")
  #   if UserGroupLink.find(:all, :conditions => ["user_id = ? and group_id = 1", user_id])
  #     return true
  #   else
  #     return false
  #   end
  # end

end
