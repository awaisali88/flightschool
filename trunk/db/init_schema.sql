create language plpgsql;

-- Table storing all of the schools/clubs served by the application
create table schools(
  	id 							serial primary key,
  	name 						text,
	root_document				integer not null
	-- (references documents table) The root CMS document for the school - used to define mapping 
	-- between documents and schools through a hierarchy tree.
	-- All of the content related to a school refer_to up the tree to the school's root_document
);

-- Table storing the offices (different locations) of the club
create table offices(
  	id 							serial primary key,
  	name 						text,
	zipcode						text,
	school_id					integer not null references schools(id)
);

-- Main table for user information - every registered user has a row. Includes authenication data
CREATE TABLE users (
	id 							SERIAL PRIMARY KEY,			
	--uuid, Rails want this column to be named this way		
	email 						TEXT CHECK (LOWER(email) = email) UNIQUE NOT NULL,		
	--UNIQUE will automatically create an index	
	first_names 				TEXT NOT NULL,					
	last_name 					TEXT NOT NULL,				

	email_verified				BOOLEAN DEFAULT FALSE,
	account_suspended			BOOLEAN DEFAULT FALSE,
				
	--Columns below are inherited from Rails Login Engine	
	salted_password 			TEXT NOT NULL,				
	salt 						CHAR(40) NOT NULL,			
	security_token 				CHAR(40) default NULL,			
	token_expiry 				TIMESTAMP default NULL,			

	created_at					TIMESTAMP NOT NULL,
	-- auto filled by Rails
	last_login         			timestamp,
	office            			integer references offices(id),
	-- user's primary office of the club
	
	hourly_rate        			real default 50.0
	-- for instructors - how much is charged per hour of instruction	

	birthdate					DATE,
	is_us_citizen				BOOLEAN,

	portrait_id 				INTEGER,	
	--personal picture reference

	user_biography 				TEXT,					
	--user-supplied personal bio/description


	share_profile				BOOLEAN default false,			
	share_contact_info			BOOLEAN default false,			
	share_certification_info	BOOLEAN default false,			
	--allow others to see information flags

	faa_physical_date					DATE,	
	last_biennial_or_certificate_date	DATE,
	--can be biennial, new rating or new certificate date
	
	-- following columns used for flagging changes on fields that need admin approval
	birthdate_approved 			boolean default true,
	physical_approved 			boolean default true,
	biennial_approved 			boolean default true,
	us_citizen_approved 		boolean default true
);

-- Table of images, with captions - a user can set an image as a portrait in extra_user_info. 
-- We will need to add an ON DELETE trigger for removing actual image data whenever the 
-- referencing row is removed. 
CREATE TABLE images (
	id							SERIAL PRIMARY KEY,
	user_id						INTEGER NOT NULL REFERENCES users(id),	
	image_binary				bytea NOT NULL,
	thumbnail	   				bytea NOT NULL,
	image_type					TEXT NOT NULL,
	created_at					TIMESTAMP NOT NULL,			
	caption						TEXT
	
);

ALTER TABLE users ADD CONSTRAINT imagefk FOREIGN KEY (portrait_id) REFERENCES images (id) MATCH FULL;

-- Table storing binary files uploaded to the site CMS
create table files(
	id							SERIAL PRIMARY KEY,
	user_id						INTEGER NOT NULL REFERENCES users(id),	
	file_binary					bytea NOT NULL,
	file_type					TEXT NOT NULL,
	file_name					TEXT NOT NULL,
	created_at					TIMESTAMP NOT NULL,			
	description					TEXT
);

-- table holding pilot certificate information
CREATE TABLE user_certificates (
	id							SERIAL PRIMARY KEY,
	user_id						INTEGER NOT NULL REFERENCES users(id),
        -- pilot's id
	approved 					boolean default false,
	certificate_category		text NOT NULL,
	airplane_sel_rating 		boolean default false,
	airplane_mel_rating		 	boolean default false,
	helicopter_rating 			boolean default false,
	instrument_rating 			boolean default false
);

-- Table of user addresses - a user can have multiple registered addresses
CREATE TABLE user_addresses (
	id							SERIAL PRIMARY KEY, 			
	user_id						INTEGER NOT NULL REFERENCES users(id),
	address_line1 				TEXT NOT NULL,					
	address_line2 				TEXT,				
	city 						TEXT NOT NULL,				
	state_province 				TEXT,   
	postal_code 				TEXT,				
	country						TEXT
);

-- Table of user phone numbers - a user can have multiple registered numbers
CREATE TABLE user_phone_numbers (
	id							SERIAL PRIMARY KEY, 			
	user_id						INTEGER NOT NULL REFERENCES users(id),
	phone_number				TEXT NOT NULL,
	is_txt_capable				BOOLEAN
);
      
-- Tables with user group definitions.
-- Groups are generic and function for any purpose requiring a set of users 
CREATE TABLE groups (
	id							SERIAL PRIMARY KEY, 			
	group_name					TEXT UNIQUE NOT NULL,	
	group_type					TEXT NOT NULL,
	CONSTRAINT valid_group_type	CHECK (group_type IN ('role','subscription'))
);

-- Mapping between users and groups - name follows Rails conventions
CREATE TABLE groups_users (
	id							SERIAL PRIMARY KEY,
	user_id						INTEGER NOT NULL REFERENCES users(id), 		
	group_id					INTEGER NOT NULL REFERENCES groups(id),
	approved					BOOLEAN DEFAULT FALSE	
);

CREATE UNIQUE INDEX groups_users_index on groups_users (user_id,group_id);

-- table for types of aircraft owned by the club. A type would be 'Katana','R-22', etc
create table aircraft_types(
	id							serial primary key,
	type_name					text not null,
	--model number allows for finer distinction between aircraft types - like year of make, etc
	passenger_capacity			integer not null check (passenger_capacity >= 1),
	picture						integer references images(id),
	sort_value 					integer default 0
    -- used for sorting aircraft types on schedule display
);

-- table with one row for each aircraft owned by the club
create table aircrafts(
	id			    serial primary key,
	aircraft_type	integer not null references aircraft_types(id),
	identifier     	text not null,
	equipment_description		text,
	picture			integer references images(id),
	type_equip     text,
    -- code for the class of equipment aircraft has

	color          text,
	prioritized    boolean,
	deleted        boolean default false,
	-- aircrafts can be labeled as prioritized for reservation
	office         integer references offices(id),
	-- aircraft's current home location 
	hourly_rate    real default 50.0,
	-- how much is charged per hour of flight (based on hobb's)

    -- current values of hobbs meter and tach on aircrafts
	hobbs          real not null default 0,
    tach           real not null default 0
);

-- table for hodling per-aircraft maintenance counters
create table maintenance_dates(
   id serial primary key,
   aircraft_id integer references aircrafts(id) not null,
   expires integer not null,
   -- value of aircraft tach at which maintenance needs to be performed
   description text not null,
   comments text
);

-- table for aircraft/instructor reservations
-- reservation specifies aircraft and times of checkout, and optionally an instructor
-- this table is also used for setting times blocked out by instructors and administrators
create table reservations(
	id			serial primary key,
	created_by 		integer not null references users(id),
	aircraft_id		integer references aircrafts(id),
	instructor_id		integer references users(id),
	time_start		timestamp not null,
	time_end		timestamp not null,
    reservation_type text not null,
	json_cache		text,
	-- caches JSON representation of the representation for performance
    status text not null check (status in ('created','approved','canceled','completed')),
    constraint valid_reservation_type check (reservation_type in ('instructor_block','aircraft_block','booking'))
);

-- trigger for ensuring that non-canceled reservations do not overlap
CREATE OR REPLACE function check_reservation_overlaps() returns trigger AS $reservation_overlap_trigger$
BEGIN       
   if NEW.status!='canceled' and 
	  (select count(*) from reservations r where 
	  	(r.aircraft_id=NEW.aircraft_id or r.instructor_id=NEW.instructor_id) and 
		r.id != NEW.id and 
		r.status!='canceled' and
		r.time_start<NEW.time_end and 
		r.time_end>NEW.time_start)>0 THEN
		return NULL;
	else
		return NEW;
	end if;
END 
$reservation_overlap_trigger$ LANGUAGE plpgsql;       

CREATE trigger reservation_overlap_trigger
  after INSERT OR UPDATE ON reservations 
  FOR each ROW EXECUTE PROCEDURE check_reservation_overlaps();

--  table stores changes made to reservations, which are used for emailing notifications to pilot whose reservations have been altered.
create table reservations_changes as select * from reservations;
alter table reservations_changes add column sent boolean default true;
-- sent set to false indicates that the change needs to be sent out to reservation owner
           
-- trigger for copying new reservations to reservations_changes table
create or replace function mirror_reservation() returns trigger as $mirror_reservations$
begin      
   insert into reservations_changes select NEW.*, true;  
   return NEW;
end 
$mirror_reservations$ language plpgsql;          
       
create trigger mirror_reservations
 after insert on reservations
 for each row execute procedure mirror_reservation();
            
-- trigger for updating sent column when reservation changes are made
create or replace function update_reservation_change() returns trigger as $update_reservation_changes$
begin      
  if (select sent from reservations_changes where id = NEW.id) then
     delete from reservations_changes where id = NEW.id;
     insert into reservations_changes select *, false from reservations where reservations.id = NEW.id;  
  end if;           
  return NEW;
end 
$update_reservation_changes$ language plpgsql;          

create trigger update_reservation_changes
  before update on reservations
  for each row execute procedure update_reservation_change();

--  table for storing rules used for automatic reservation verification
-- all of the rules in this table are run when reservation is made to determine if reservation needs dispatcher's review
create table reservation_rules(
   id serial primary key,
   description text not null,
   type text check (type in ('SchedulingAccessRule','ReservationApprovalRule','ReservationAcceptanceRule')),
   name text not null

   -- code is evaluated within the controlled code. Reservation is flagged
   -- as needing approval if at least one of the rule's code evaluates to "false"
);

-- table defines per-user exceptions to the reservation rules
-- a row in this table means that reservation rule reservation_rule_id does not apply to user user_id
create table reservation_rules_exceptions(
   id serial primary key,
   user_id integer not null references users(id),
   reservation_rule_id integer not null references reservation_rules(id),
   expiration_time timestamp           
   -- not used     
);


-- main table for website content
-- table columns are generic enough to accomodate almost all types of the content for the website
-- including news, articles, forum posts, and comments on any of the previous items. 
create table documents(
	id						serial primary key,
	refers_to				integer	references documents(id),
	created_by				integer not null references users(id),
	last_updated_by			not null references users(id),
	-- user that last updated this row
	created_at				timestamp not null,
	updated_at 				timestamp not null,
	mime_type				text not null,
	one_line_summary		text not null,
	body					text not null,
	type					text not null,
	-- document type
	status					text not null,	
	url_name       			text,
	-- url_name is used for organizing static pages into a tree hierarchy
	-- each page's URL is produced by concatenating url_names while traversing
	-- refers_to links up to the root document.
	flight_plan    			text,
    -- used for ride-sharing forum. Stores flight plan as space 
    -- separated list of airport codes.
	published_version		integer,

	constraint valid_type		check (type in ('StaticContent','NewsArticle', 'Forum','ForumTopic','ForumPost', 'ReservationComment', 'RootDocument')),
	constraint valid_status		check (status in ('submitted','approved','rejected')),
    constraint valid_url_name 	check ((url_name LIKE '%/%') = FALSE)
);  

-- for unique URL to static page mapping
create unique index document_url_index on documents (refers_to,url_name);        

-- audit table for site content providing versioning functionality
create table documents_audit as select * from documents;
alter table documents_audit add column version integer;

-- trigger to maintain document audit table
CREATE OR REPLACE FUNCTION process_doc_audit() RETURNS TRIGGER AS $doc_audit$
BEGIN 
INSERT INTO documents_audit SELECT NEW.*, (select greatest(max(version),0)+1 from documents_audit where id=NEW.id); 
RETURN NEW; 
END; 
$doc_audit$ LANGUAGE plpgsql;
            
CREATE TRIGGER doc_audit 
AFTER INSERT OR UPDATE ON documents 
FOR EACH ROW EXECUTE PROCEDURE process_doc_audit();

-- allows linking reservations to forum posts and other documents. Used for 
-- reservation comments system
create table documents_reservations(
	reservation_id 		integer not null references reservations(id),
	document_id 		integer not null references documents(id)
);


-- main billing table, storing all charges against users' accoutns along with any flight information relevant to the charge 
create table billing_charges(
   id               serial primary key,
   created_at       timestamp,
   created_by       integer not null references users(id),
   -- office worker that entered the record
   refers_to        integer references billing_charges(id),
   -- unused
   type      		text check(type in ('FlightRecord','CorrectionRecord','DepositRecord','FeeRecord','SuppliesRecord')),
   flight_date      date,
   user_id          integer not null references users(id),
   -- user against whom the charge is made
   instructor_id    integer references users(id),
   aircraft_id      integer references aircrafts(id),
   -- values below are stored as absolute values (not just the end digits)
   hobbs_start      real,
   hobbs_end        real,
   tach_start         real,
   tach_end         real,
   ground_instruction_time real,
   aircraft_rate    real,
   instructor_rate  real,
   charge_amount    real not null,
   running_total    real,
   notes            text
);

-- trigger for maintaining running totals in billing_charges table            
CREATE OR REPLACE function process_billing_charge() returns trigger AS $compute_billing_charge$
BEGIN       
   UPDATE billing_charges  SET running_total = (coalesce((select running_total FROM billing_charges WHERE (user_id = NEW.user_id) ORDER BY id DESC limit 1 offset 1),0) - NEW.charge_amount) WHERE id = NEW.id;
   return NEW;
END 
$compute_billing_charge$ LANGUAGE plpgsql;          

CREATE trigger compute_billing_charge
  after INSERT ON billing_charges 
  FOR each ROW EXECUTE PROCEDURE process_billing_charge();
            
-- trigger for maintaining tach and hobbs value for aircrafts
CREATE OR REPLACE function update_aircraft_stats() returns trigger AS $process_flight_record$
BEGIN       
  if NEW.type != 'flight' THEN
    return NEW;
  END if;
  UPDATE aircrafts SET hobbs = greatest(NEW.hobbs_end,hobbs) WHERE id = NEW.aircraft_id;
  UPDATE aircrafts SET tach = greatest(NEW.tach_end,tach) WHERE id = NEW.aircraft_id;
  return NEW;
END 
$process_flight_record$ LANGUAGE plpgsql;
          
CREATE trigger process_flight_record
  after INSERT ON billing_charges 
  FOR each ROW EXECUTE PROCEDURE update_aircraft_stats();
