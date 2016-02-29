# Image/Binary Document Content Module #

## Purpose ##
Image/Binary Document Content module allows following:
  * Uploading of images and other binary documents
  * Thumbnailing of images
  * URLs for displaying images and documents stored in database (both original images and thumbnails)

## Design ##
  * Image data is stored in the Images table
  * Binary document data is stored in the Files table
  * RMagick library is used for processing images and generating thumbnails
  * image upload interface is a partial template that can be inserted in any page that needs image upload functionality
    * by default, image upload partial assumes presence of the form input with DOM id "document\_body" which will receive the links to uploaded images picked by user
  * Images are served through URLs of form /image/show/# and image/thumb/# for full image and thumbnail of image with id #

## Sources ##
  * trunk/app/controllers/image\_controller.rb
  * trunk/app/controllers/file\_controller.rb