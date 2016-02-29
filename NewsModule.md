# News Publishing Module #

## Purpose ##
News publishing module offers following functionality:
  * Storing site-wide news articles
  * Online interface for article editing
  * Centralized news page showing recent (approved) articles
  * Commenting on the articles #8

## Design ##
  * Article content is stored in the [wiki:DBSchema#documentstable documents] table.
  * status column in documents is used for tracking editorial status of the article, allowing only articles with approved status to be shown on the main news page

## Sources ##
  * trunk/app/controllers/news\_controller.rb