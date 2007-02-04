class Image < ActiveRecord::Base
require 'RMagick'
require 'tempfile'

	belongs_to :user
	
  validates_format_of :image_type, :with => /^image/,
  :message => "--- you can only upload images "

  def image=(picture_field)
    self.image_type = picture_field.content_type.chomp
    img = Magick::Image::from_blob(picture_field.read).first
    thumb = 0
    if(img.rows<=100 and img.columns<=100)
      thumb = img
    else
      img.change_geometry('100x100') { |cols, rows, i|
       thumb = i.resize(cols, rows)
      }
    end
    self.image_binary = img.to_blob
    self.thumbnail = thumb.to_blob
  end
  
end
 