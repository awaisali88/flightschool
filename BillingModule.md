# Accounting/Billing Module #

## Purpose ##
Accounting Module provides following functionality:
  * Data entry interface for billing charges against pilot accounts, including any relevant flight information
  * Administrator reports showing per-aircraft usage and revenue statistics
  * Pilot reports showing pilot's account transactions with running totals
  * Accounting data export to CSV format

## Design ##

All recorded transactions (charges, deposits, etc) are stored in a single table ([wiki:DBSchema#billing\_chargestable billing\_charges]) The system treats all recorded transactions as permanent - there is no way to edit or remove a created transaction, so a correctional transaction must be applied when a mistake has been made. All transactions are stored as amount charged (i.e. subtracted) from the account - so deposits must appear as charges with negative amounts. An important aspect of the data entry is the way the values of hobbs meter and tachometer readings are entered. While dispatchers only enter last 3 digits (XX.X) of each value, full values are always stored in the database. The full values are computed based on the most recent previous values, rolling over to next 100 when necessary.

To reduce the computational costs of producing per-pilot reports, running totals per account are kept with each recorded billing entry. `compute_billing_charge` trigger is enabled on the table to maintain the running total column. Another trigger on the table is the `process_flight_record` trigger - which is set up to automatically update the values of `tach` and `hobbs` columns of [wiki:DBSchema#aircraftstable aircrafts] table, based on inserted flight-related charges.

All of the data entry forms use Javascript to make data entry more efficient - previously entered values are recalled as defaults when appropriate, there are autocompletes (implemented with Prototype helpers) for names and aircraft, and the instructor and aircraft rates are automatically recalled when necessary data is entered.

### Model ###
  * All billing information is stored in billing\_charges table

### Implementation ###
  * trunk/app/controllers/billing\_controller.rb