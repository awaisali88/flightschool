  def new_content_rss
    @posts = Document.find(:all, :limit=>n_items, :order=> 'created_at', :conditions => "document_type = 'news'")
    render_without_layout
  end