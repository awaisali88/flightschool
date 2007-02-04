class UploadedFile < ActiveRecord::Base

  set_table_name 'files'
	belongs_to :user
	
  def file=(file_field)
    self.file_type = file_field.content_type.chomp
    self.file_binary = file_field.read
    self.file_name = file_field.original_filename
  end
  
end
