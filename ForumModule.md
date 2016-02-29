# Discussion Forum Module #

## Purpose ##
This module provides following functionality:
  * Storage and display of forum topics and posts
  * Creation of new topics
  * Addition of repies to pre-existing topics

## Design ##
Both topics and posts utilize the [wiki:DBSchema#documentstable documents] table.  The topics use the table as follows:
  * The one\_line\_summary column contains the topic title.
  * The column last\_updated by refers to the user who first created the topic.
  * Topics contain no relevant body.
Posts, on the other hand:
  * Also uses one\_line\_summary for the topic title.
  * Use the body column for the post body.
  * Utilize last\_updated for the last updated user (edited posts are versioned).
  * Contain a reference to the containing topic in refers\_to.
When displayed in the forum root, the topics are ordered by the time of the most recent post.  They are displayed as the topic title and the number replies.  On the topic pages, the posts are also organized by the date of post, though the most recent post is at the bottom.  The posts are displayed with the original author (not the most recent updater), the date of original posting, and the body of the most recent edit.

## Sources ##
  * /trunk/app/controllers/forum\_controller.rb