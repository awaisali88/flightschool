class SearchController < ApplicationController

def searchbox
  render :partial => 'searchbox'
end

def search
  @page_title = 'Search Results for "'+params[:query]+'"'
  query = params[:query].downcase.split.map{|x| x+' & '}.join[0..-4]
  @results = Document.find(:all, :conditions => ["text_index @@ ?::tsquery and document_type = 'static_page'",query])
end

end