# Static Content Module #

## Purpose ##
This module provides following functionality:
  * Storing static pages (About, FAQ, Contact Us, etc)
  * Online interface for editing static pages and hierarchically organizing them
  * Standardized URL to static page mapping

## Design ##
Like most other text content in the system, the static pages are stored in the [wiki:DBSchema#documentstable documents] table.
  * The document\_type column value for static pages is 'static\_page'.
  * refers\_to column is used to point to the parent of a page, establishing hierarchy
  * there exists a root static page (created at DB init)
    * root page is defined as a row in documents table with document\_type = 'static\_page' and refers\_to = NULL
  * one\_line\_summary column is used to store static page title
  * url\_name column is used for mapping from URLs to static pages
    * URL for a page are the aggregated url\_names of the pages on the path from root page to the specific page, separated by '/'

URL to static page mapping:
  * routes.rb file is altered to refer all URLs of the form /content/**to the static page controller
  * URL for a page is always of the form /content/path/to/document where pieces of URL after /content/ are the url\_name column values of the pages on the path from root page to the specific page**

## Sources ##
  * trunk/app/controllers/static\_controller.rb