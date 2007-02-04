class ReservationComment < Document

def initialize(body,user)
  super ({:body => body,
  :status=>'approved',
  :created_by => user,
  :one_line_summary => '',
  :mime_type => 'text/plain',
  :last_updated_by => user,
  })
end

end
