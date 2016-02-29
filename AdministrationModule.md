# Administration Module #

## Purpose ##
This module is designed give administrators the ability to:
  * View all of the current members, ordered by their preferred attribute.
  * Navigate to any member's profile.
  * Approve new users or profile edits.
  * Suspend users.
  * Change group membership of users.

## Design ##
  * The groups that the administrator can edit membership for is represented in the Groups table.
  * The administrator's profile options are represented by the approved\_by\_admin and account\_suspended columns in the Users table.

## Sources ##
  * /trunk/app/controller/admin\_controller.rb