# Reservation/Scheduling Module #

## Purpose ##
  * Enable users to create reservations online
  * Enable users to receive reminderes and notifications about their reservations
  * Allow dispatchers view, edit, and approve reservations
  * Allow administrator to manage aircraft information
  * Allow instructors to see their reservations, and block out times from their schedule

## Design ##
### Rule-Based Verification System ###
Reservation system includes a powerful rule-based reservation verification system used for automatically flagging reservations that need dispatcher approval. All of the rules are stored as pieces of code that evaluate to either true or false. Upon reservation creation, all of the rules that apply to the user are evaluated and if at least one of the rules evaluates to "false", then the reservation is flagged for admin approval (its status is set to "created"). Dispatchers may then approve flagged reservations (displayed on /schedule/need\_approval page).
If all rules pass, then the reservation's status is automatically set to "approved".

The rules may use the following objects in their code - `user` and `reservation`. These correspond to instances of User and Reservation class respectively and let rules get information about person making the reservation and the reservation itself.

### Email Reminders and Notifications ###
The scheduling system implements email reminders and notifications for reservations. Once a day a script (source:trunk/lib/tasks/schedule\_reminders.rb) is run on the server, sending out reminders (using ScheduleMailer ActionMailer controller) for users with reservations on the next day.

To be able to notify users about changes in their reservations, the system keeps a separate table [wiki:DBSchema#reservations\_changestable reservations\_changes]. This table contains reservations in the form the user has last seen them. Whenever a reservation is updated, the `sent` column flag is updated in corresponding row in [wiki:DBSchema#reservations\_changestable reservations\_changes] table to read false, indicating that the reservation may have potentially changed since the last time user has seen it.

Periodically (every hour), a script is run on the server (source:trunk/lib/tasks/schedule\_reminders.rb) checking if any reservations has been changed without telling the user (`sent` column set to false and the content of reservations\_changes row different from corresponding reservations row), and if so sends an email to the user, while updating the `sent` column to true. This way the system consistently maintains the set of reservations that need notifications, and delivers the notifications regularly.

### Model ###
  * All aircraft information is stored in [wiki:DBSchema#aircraftstable aircrafts] and [wiki:DBSchema#aircraft\_typestable aircraft\_types] tables (managed by Aircraft and AircraftType classes respectively)
  * The schedule availability information is held in [wiki:DBSchema#reservationstable reservations] table (includes bookings, instructor and aircraft blocks)
  * Reservation rules are stored in [wiki:DBSchema#reservation\_rulestable reservation\_rules] table and per-user exceptions for them are in [wiki:DBSchema#reservation\_rules\_exeptionstable reservation\_rules\_exceptions] table.

All reservations are checked for consistency before beign saved. No non-canceled reservations are allowed to overlap in time, or have end\_time smaller than start\_time.

### Implementation ###
**/trunk/app/controllers/schedule\_controller.rb** /trunk/app/controllers/reservation\_controller.rb