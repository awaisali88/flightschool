# User Registration Module #

## Purpose ##
User registration module is responsible for basic user management functionality, including:
  * User signup and email verification
  * User authenication
  * Lost password recovery
  * Permission checking
  * User administration
    * creation of accounts by admin
    * approving and suspending accounts

## Design ##
User Registration Module is based on the [Rails Salted Hash Login Engine](http://api.rails-engines.org/login_engine/)

Model:
  * All user accounts are stored in a single users table in the database.
  * User's email is their Login ID
  * User's password is stored in the database in SHA digested form

Permission Checking:
  * Permission checking code resides in a PermissionsChecker Ruby module in /lib.
  * All controllers requiring permissions register a before\_filter hook that links to load\_permissions method in PermissionsChecker, which refreshes user's permissions.
  * Controllers can use permission level methods defined in PermissionsChecker to verify certail level of authorization
    * Example: `admin? , can_edit_any_user_info?`

## Sources ##
  * trunk/app/controllers/user\_controller.rb
  * trunk/lib/permissions\_checker.rb