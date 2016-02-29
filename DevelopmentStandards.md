# Development Standards #

> Using Rails framework for its core, Project FlightSchool inherits a lot of development conventions from it. With a notable exception of strong reliance on RDBMS integrity constraints, in most instances everything is done "The Rails Way" - we will go through the convention details to illustrate what this means for our project.

## Tools and Languages ##
Project FlightSchool uses following tools:
  * PostgreSQL 8.1
  * Rails 1.1 framework

Languages used are PL/pgSQL for RDBMS procedures, Ruby for server-side scripting, Javascript for client-side scripting, and JSON for Javascript

&lt;-&gt;

Ruby interfacing.
Connection to RDBMS is managed through ActiveRecord ORM layer, which is part of Rails framework.

## Coding Conventions ##
### URL Naming ###
All of the URLs are abstract (handled by Rails routing). Project FlightSchool convention is to use underscores for URLs (as opposed to dashes), although URL parts abbreviated to one word are preferred. For forms, the GET and POST are sent with separate URLs - typically named '`new_foo`' or '`edit_foo`' for GET and '`save_foo`' for POST. Similar name convention is used for AJAX-style pseudo-POSTS.

For static content pages (such as 'About','FAQ','Contact Us',etc pages) the URL is of the form `/content/path/to/document`. The path to document is the path accumulated by
traversing `refers_to` DB references in `documents` table from the document to the root static page (also in DB), collecting contents of `url_name` column of each
document on the way.

### Class/Variable Naming ###
Our code fully follows Rails conventions for Class/Variable Naming. This means:
  * CamelCase for class names
  * underscore notation for all local and instance variables
We also adopt following conventions
  * all [wiki:Migrations] are composed of single-word describing migration purpose, followed by abbreviated date of creation. For example ImageMar10 can be a name for Migration class.
  * string literal notation for passing parameters in a hash as opposed to using symbol names. In other words we write ` redirect_to :controller=>'news',:action=>'index' ` as opposed to ` redirect_to :controller=>:news,:action=>:index `

### Controller Code ###
MVC separation should be enforced throughout the code. This means that the controller code does not perform any data formatting or rendering, with the exception of inline RJS templates. We make exception for inline RJS since its nature is same as of page redirecting, and using inline RJS as opposed to separate RJS templates provides for better code organization.

As a convention, controller code should not be doing any complicated ActiveRecord queries. If a complex query is required, or if a query is used repeatedly throughout the controller code, the query should be encapsulated in a helper method in appropriate Model class.

Every url-mapping controller code that answers to a GET request must set special `@page_title` instance variable to a string containing the title for the page about to be rendered. This variable is used for a standardized way of setting page titles across the site, and is also needed for correct operation of [wiki:breadcrumbs] hierarchical navigation module.

### View Code ###
View code reuse is encouraged through use of partial .rhtml templates. A global application layout template is defined in /app/views/layout/application.rhtml, and all view templates rendered for an action are embedded in this top-level layout.

### Model Code ###
Model validations must be at least as strict as the constraints imposed by RDBMS constraints on the underlying tables, to prevent ActiveRecord errors.

### Form Processing ###
Following conventions are used for form processing:
  * An object of the type corresponding to the form data is created or loaded from DB in controller and passed to view template
  * ActiveHelper methods like select, text\_area, etc are used in view template code
    * any old values from the passed object are automatically prefilled in the form
  * Upon POST, the values from the form-fields are passed in params hash to the processing controller method
  * ActiveRecord::Base object is created or loaded using the params hash
  * Field values are validated using ActiveRecord validation mechanism, any errors are stored as an array inside the object being validated
  * If there are any errors, the errors array for the object is rendered to the user.

## Application Configuration ##
At the moment, each module is responsible for its own configuration, which is done through configuration files (i.e. values are hardcoded).
We plan to implement a database-backed configuration system which would store <key,value,module> triplets - the system would cache the values
on application startup so that no unnecessary database requests are made.

## Documentation Procedures ##
All of the high level documentation such as module design documentation belongs to this wiki. For source file documentation, RDoc is used.
### For a Module ###
Each module must have following documentation:
  * a high-level design document describing module purpose and its architecture
  * list of controller source files related to the module
  * all source files must have Author:: and Copyright:: labels
  * per-method documentation for all controller code
    * purpose and effect
    * expected URL parameters if any (Params::)
    * assumptions about [wiki:Session session] content (Session::)
  * per-template documentation for all view code
    * purpose and effect
    * instance variables/partial parameters to be passed
    * templates/controllers rendered from if it is a partial

### For a Shared Procedure ###
Shared procedures are to be treated the same way as Module controller code.

### For a  Migration ###
Each Migration must have following documentation:
  * Purpose
  * Schema change summary
  * Tables and Columns affected
