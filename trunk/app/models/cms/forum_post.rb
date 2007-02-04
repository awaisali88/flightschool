class ForumPost < Document

  belongs_to :topic, :class_name=>'ForumTopic',:foreign_key=>'refers_to'

  def initialize(hash,user)
    if hash[:one_line_summary]==nil then hash[:one_line_summary]='' end
    super(hash,user)
    @attributes['mime_type'] = 'text/plain'
    @attributes['status'] = 'approved'
    
  end

end
