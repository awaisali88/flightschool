class ForumTopic < Document

  belongs_to :forum, :class_name=>'Forum',:foreign_key=>'refers_to'
  has_many :posts, :class_name=>'ForumPost',:foreign_key=>'refers_to'
  before_save :fill_summary
  
  #called before a forum topic is created - fetches the topic subject from the first post in the topic
  def fill_summary
    @attributes['one_line_summary'] = posts[0].one_line_summary
  end

  def initialize(parent_forum,user)
    super nil,user
    @attributes['mime_type'] = 'text/plain'
    @attributes['status'] = 'approved'
    @attributes['body'] = ''
    @attributes['refers_to'] = parent_forum.id
  end
  
  def reply_count
    return (ForumPost.count ["refers_to = ?",id]) - 1
  end

  def latest_post
    return ForumPost.find(:first, :conditions =>["refers_to = ? AND status!='rejected'",id], :order => "created_at DESC")
  end
  
  def subject
    return one_line_summary
  end
  
end
