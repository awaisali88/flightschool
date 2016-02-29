# User Profile Module #

## Purpose ##
This module provides following functionality:
  * Displays users' profiles.
  * Online interface for editing of various aspects of user profile.

## Design ##
The profiles being edited can be found in both the Users table, and the various tables associated with items which a user can have more than one of (user\_addresses, user\_phone\_numbers, etc).  The documentation of these tables can be found in the DatabaseSchema

Most columns of the users Users table simply refers to the aspect it is named for in the profile/profile editor (i.e. birthdate => birthdate).  The rows which refer to multiple objects, as mentioned previously, contain references to the rows in other tables associated with the particular user.  Users can has as few or as many of the multiple items as they desire.

## Source ##
  * trunk/app/controllers/profile\_controller.rb