#####################################################################################
#
# ForumController implements the community section of the system, allowing users
# to submit and view posts and threads and search for threads by destination
#
# Authors:: Lev Popov levpopov@mit.edu
# 
#####################################################################################

class ForumController < ApplicationController

  before_filter :login_required
  before_filter :force_single_column_layout

  # main forum view, showing all threads for a forum
  def index
    @forum = Forum.find_by_name params[:forum_name]
    @page_title = @forum.description
    @pages,@topics = paginate :forum_topic, :per_page => 20, :conditions => ["refers_to=?",@forum.id],
                    :order=>"(select max(updated_at) from documents d where d.refers_to = documents.id and d.status='approved')  desc"
  end
  
  # provides a view of each post within a given topic
  def view
    @topic = ForumTopic.find_by_id params[:topic]
    @page_title = @topic.subject
    @forum = @topic.forum
    @post_pages, @posts =  paginate :forum_post, :per_page => 10,
          :conditions => ["refers_to = ?", @topic.id],
          :order_by => "created_at" 
  end
    
  # creates a new topic in the forums
  def create_topic
    @page_title = 'New Topic'
    @forum = Forum.find_by_name params[:forum_name]
    
    if @forum == nil
      flash[:warning] = 'Invalid forum specified.'
      redirect_to :back
      return 
    end
    
    case request.method
    when :post    
      @post = ForumPost.new (params[:post],current_user)        
      if @post.one_line_summary == '' or @post.body == ''
        flash[:warning] = 'Cannot create a topic with empty subject or empty body.'
        redirect_to :back
        return 
      end      
      
      @topic = ForumTopic.new (@forum,current_user)   
      @topic.posts << @post
      if @topic.save
        flash[:notice] = 'Topic added.'
        redirect_to :action => 'view', :topic => @topic.id
      else
        flash[:warning] = 'Error creating a forum topic.'
        redirect_to :back
      end
    end
  end
  
  # adds a reply to a given forum topic
  def create_post
    @topic = ForumTopic.find_by_id(params[:topic])
    if @topic == nil
      flash[:warning] = 'Invalid topic specified.'
      redirect_to :back
      return 
    end      
    
    @post = ForumPost.new(params[:post],current_user)  
    if @post.body == ''
      flash[:warning] = 'Please enter something in the post body.'
      redirect_to :back
      return 
    end
    @topic.posts << @post
    if @post.save
      flash[:notice] = 'Post added.'
      redirect_to :action => 'view', :topic => @topic.id
    else
      flash[:warning] = 'Error creating a forum post.'
      redirect_to :back
    end
  end
  
  
  # hides a given thread from non-admin users
  def hide_topic
    redirect_to :back
    return unless has_permission :admin
    topic = ForumTopic.find_by_id(params[:id])
    topic.status = "rejected"
    topic.save
  end
  
  # allows non-admin users to see a previously hidden thread
  def show_topic
    redirect_to :back
    return unless has_permission :admin
    topic = Document.find_by_id(params[:id])
    topic.status = "approved"
    topic.save
  end
  
  # hides a given post from non-admin users
  def hide_post
    redirect_to :back
    return unless has_permission :admin
    post = Document.find_by_id(params[:id])
    post.status = "rejected"
    post.save
  end
  
  # shows a previously hidden post to non-admin users
  def show_post
    redirect_to :back
    return unless has_permission :admin
    post = Document.find_by_id(params[:id])
    post.status = "approved"
    post.save
  end
  
  
  
end
