class NewsArticle < Document

  validates_each :one_line_summary,:body do |record, attr, value|
    record.errors.add attr, 'is empty' if (value == nil or value.strip == "")
  end

end
