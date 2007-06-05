class Forum < Document

  has_many :topics, :class_name=>'ForumTopic',:foreign_key=>'refers_to'

  def initialize name
    super ({:url_name=>name,:mime_type=>'text/plain'})
    @attributes['status'] = 'approved'
    @attributes['body'] = ''
    @attributes['one_line_summary'] = name
  end

  def self.find_by_name(name)
    return find :first,:conditions=>['url_name=?',name]
  end
  
  def name
    return url_name
  end
  
  def description
    return one_line_summary
  end
    
end