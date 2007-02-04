class Document < ActiveRecord::Base
 belongs_to :creator,
    :class_name => 'User',
    :foreign_key => 'created_by'

 belongs_to :last_updater,
    :class_name => 'User',
    :foreign_key => 'last_updated_by'


def initialize(hash={},user=nil)
  super(hash)
  if user!=nil
    @attributes['created_by']=user.id
    @attributes['last_updated_by']=user.id
  end
end

def created_by= user
  @attributes['created_by']=user.id
end

def last_updated_by= user
  @attributes['last_updated_by']=user.id
end

def versions
  return Document.find_by_sql(['select * from documents_audit where id=? order by version desc',id])
end

def get_version version
  return Document.find_by_sql(['select * from documents_audit where id=? and version=?',id,version])[0]
end

def parent
  if refers_to.nil?
    return nil
  else
    return Document.find_by_id(refers_to)
  end
end

def creation_time
  return created_at>(Time.now-3600*24*365) ? created_at.strftime('%b %d, %H:%M') : created_at.strftime('%b %d, %H:%M, %Y')
end

def last_updated_time
  return updated_at>(Time.now-3600*24*365) ? updated_at.strftime('%b %d, %H:%M') : updated_at.strftime('%b %d, %H:%M, %Y')
end

end
