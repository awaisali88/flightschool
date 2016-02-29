# Getting Started with FlightSchool Development #

The best way to get into development is to check out the code from svn using `svn checkout http://flightschool.googlecode.com/svn/trunk/ flightschool` and look around.

## Getting Around the Source ##

All of Project FlightSchool source is organized into modules, each responsible for a particular piece of app functionality. See the [Documentation](Documentation.md) page for design docs on each of the modules, as well as the pointers to source files used by each of them.

### Controller Code ###

Typically you would want to be able to locate a piece of code that is responsible for a particular request made to the server. This is very simple in Rails - simply follow the config/routes.rb file to see URL to controller action bindings. (More info on Rails routes.rb file is available [here](http://wiki.rubyonrails.org/rails/pages/Routes)).

### Model Code ###

Once you see the controller code, you would be interested in how it manipulates the data drom the database. Rails' ActiveRecord is used to wrap database tables with Model classes, and following the convention, each class name is directly derived from the table name it wraps. Once you know the name of the table, you can see its schema definition on the [schema page](DatabaseSchema.md).