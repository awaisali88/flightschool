class StaticContent < Document
  
  validates_each :url_name,:one_line_summary do |record, attr, value|
    record.errors.add attr, 'is empty' if (value == nil or value.strip == "")
  end
  
  def initialize params={},user=nil,school=nil
    if params[:mime_type].nil?
      params.merge!({:mime_type=>'text/plain'})
    end
    
    super params,user
    @attributes['status']='approved'
    @attributes['refers_to']= school.root_document unless school==nil
  end
  
  def self.find_by_school school
    return find :all, :conditions=>['refers_to=?',school.root_document],:order=>'url_name'
  end
  
end