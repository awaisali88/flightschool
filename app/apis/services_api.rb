class ServicesApi < ActionWebService::API::Base
  api_method :new_content,
             :expects => [{'n_items' => :int}],
             :returns => [[NewsArticle]]
end
