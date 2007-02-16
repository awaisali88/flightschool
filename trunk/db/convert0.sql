begin;

-- Table storing all of the schools/clubs served by the application
create table schools(
  	id 							serial primary key,
  	name 						text,
	root_document				integer not null
	-- (references documents table) The root CMS document for the school - used to define mapping 
	-- between documents and schools through a hierarchy tree.
	-- All of the content related to a school refer_to up the tree to the school's root_document
);


ALTER TABLE offices add COLUMN zipcode text;
ALTER TABLE offices add COLUMN school_id integer references schools(id);

ALTER TABLE documents RENAME COLUMN document_type TO type;
ALTER TABLE documents_audit RENAME COLUMN document_type TO type;

--add position column
create table tmp as select * from documents;
delete from tmp;
alter table tmp add column position integer;
alter table tmp add column version integer;
insert into tmp (id,refers_to,created_by,last_updated_by,created_at,
updated_at,mime_type,one_line_summary,body,type,status,url_name,flight_plan,version)
select * from documents_audit;

drop table documents_audit;
create table documents_audit as select * from tmp;
drop table tmp;  

alter table documents add column position integer;
alter table documents drop constraint valid_url_name;
alter table documents drop constraint valid_type;
update documents set type='StaticContent' where type='static_page';
update documents set type='NewsArticle' where type='news';
update documents set type='Forum' where type='forum';
update documents set type='ForumTopic' where type='thread';
update documents set type='ForumPost' where type='post';
update documents set type='ReservationComment' where type='comment';

update documents_audit set type='StaticContent' where type='static_page';
update documents_audit set type='NewsArticle' where type='news';
update documents_audit set type='Forum' where type='forum';
update documents_audit set type='ForumTopic' where type='thread';
update documents_audit set type='ForumPost' where type='post';
update documents_audit set type='ReservationComment' where type='comment';
	
alter table documents add constraint valid_type check (type in ('StaticContent','NewsArticle', 'Forum','ForumTopic','ForumPost', 'ReservationComment', 'RootDocument'));
alter table documents drop constraint valid_status;
alter table documents add constraint valid_status check (status in ('submitted','approved','rejected'));

insert into documents values(default,null,1,1,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'text/plain','East Coast Aero Club','','RootDocument','approved','','',0);
insert into schools values(default,'East Coast Aero Club',(select last_value from documents_id_seq));

update documents set url_name = (select b.url_name||'/'||a.url_name from documents a,documents b where a.refers_to=b.id and a.id=documents.id) where refers_to!=92 and type='StaticContent' and id!=92;
update documents set refers_to = (select id from documents where type='RootDocument') where refers_to=92;
delete from documents where id = 92;
update documents set refers_to = (select id from documents where type='RootDocument') where type='Forum';	
update documents set refers_to = (select id from documents where type='RootDocument') where type='StaticContent';	

update documents set url_name = one_line_summary where type='Forum';
update documents set one_line_summary = 'General Discussion' where url_name = 'general';
update documents set one_line_summary = 'Feedback Forum' where url_name = 'feedback';

delete from billing_charges;
ALTER TABLE billing_charges add COLUMN tach_start real;
ALTER TABLE billing_charges add COLUMN ground_instruction_time real;
ALTER TABLE billing_charges RENAME COLUMN charge_type TO type;
alter table billing_charges drop constraint billing_charges_charge_type_check;
alter table billing_charges add constraint billing_charges_charge_type_check 
	check(type in ('FlightRecord','CorrectionRecord','DepositRecord','FeeRecord','SuppliesRecord'));

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

alter table documents rename column position to published_version;
alter table documents_audit rename column position to published_version;
update documents set published_version = (select max(id) from documents_audit where documents_audit.id=documents.id);

update documents_audit set last_updated_by = 1 where last_updated_by not in (select id from users);

alter table users add column	birthdate					DATE;
alter table users add column	is_us_citizen				BOOLEAN;

alter table users add column	portrait_id 				INTEGER;
	--personal picture reference

alter table users add column	user_biography 				TEXT;					
	--user-supplied personal bio/description

alter table users add column share_profile BOOLEAN default true;			
alter table users add column	share_contact_info			BOOLEAN default false;			
alter table users add column	share_certification_info	BOOLEAN default false;			
	--allow others to see information flags

alter table users add column	faa_physical_date			DATE;
alter table users add column	last_biennial_or_certificate_date	DATE;
	--can be biennial, new rating or new certificate date
	
	-- following columns used for flagging changes on fields that need admin approval
alter table users add column	birthdate_approved 			boolean default true;
alter table users add column	physical_approved 			boolean default true;
alter table users add column	biennial_approved 			boolean default true;
alter table users add column	us_citizen_approved 		boolean default true;

ALTER TABLE users ADD CONSTRAINT imagefk FOREIGN KEY (portrait_id) REFERENCES images (id) MATCH FULL;

update users set birthdate	= (select birthdate from extra_user_infos where extra_user_infos.user_id=users.id);
update users set is_us_citizen	= (select is_us_citizen from extra_user_infos where extra_user_infos.user_id=users.id);
update users set portrait_id	= (select portrait_id from extra_user_infos where extra_user_infos.user_id=users.id);
update users set user_biography	= (select user_biography from extra_user_infos where extra_user_infos.user_id=users.id);
update users set share_contact_info	= (select is_contact_info_shared from extra_user_infos where extra_user_infos.user_id=users.id);
update users set faa_physical_date	= (select faa_physical_date from extra_user_infos where extra_user_infos.user_id=users.id);
update users set last_biennial_or_certificate_date	= (select last_biennial_or_certificate_date from extra_user_infos where extra_user_infos.user_id=users.id);
update users set birthdate_approved	= (select birthdate_approved from extra_user_infos where extra_user_infos.user_id=users.id);
update users set physical_approved	= (select physical_approved from extra_user_infos where extra_user_infos.user_id=users.id);

drop table extra_user_infos;

delete from groups_users where groups_users.group_id = (select id from groups where group_name ='dispatcher');
delete from groups where group_name = 'mechanic';
delete from groups where group_name = 'dispatcher';
delete from groups where group_name = 'site_owner';
	
update users set birthdate_approved = true where birthdate is null;
update users set physical_approved = true where faa_physical_date is null;
update users set biennial_approved = true where last_biennial_or_certificate_date is null;
update users set us_citizen_approved = true where is_us_citizen is null;
	
delete from documents where type='ForumPost' and refers_to is null;
delete from documents where documents.refers_to in (select id from documents a where type='ForumTopic' and (select count(*) from documents b where b.refers_to=a.id and b.status='approved')=0);
delete  from documents where type='ForumTopic' and (select count(*) from documents b where b.refers_to=documents.id and b.status='approved')=0;
	
create table files(
	id							SERIAL PRIMARY KEY,
	user_id						INTEGER NOT NULL REFERENCES users(id),	
	file_binary					bytea NOT NULL,
	file_type					TEXT NOT NULL,
	file_name					TEXT NOT NULL,
	created_at					TIMESTAMP NOT NULL,			
	description					TEXT);
	

alter table reservation_rules add column type text check (type in ('SchedulingAccessRule','ReservationApprovalRule','ReservationAcceptanceRule'));
alter table reservation_rules add column name text;
alter table reservation_rules drop column code;
delete from reservation_rules_exceptions where reservation_rule_id =6;
delete from reservation_rules where id = 6;
delete from reservation_rules where id = 7;
update reservation_rules set type='ReservationApprovalRule';
update reservation_rules set name = 'advance_scheduling' where id = 5;
update reservation_rules set name = 'recent_medical' where id = 3;
update reservation_rules set name = 'recent_certification' where id = 4;

insert into reservation_rules values(default,'Pilots must have approved Birthday, Medical, and Biennial/Certification Dates','ReservationApprovalRule','approved_dates');  

update reservation_rules set type='ReservationAcceptanceRule' where id=5;

insert into reservation_rules values(default,'Reservations cannot be made retroactively','ReservationAcceptanceRule','retroactive_scheduling');  
insert into reservation_rules values(default,'You must call the office to create or alter a reservation within 24 hours from now','ReservationAcceptanceRule','24_hours_advance');  

insert into reservation_rules values(default,'Your account is not approved by an administrator','SchedulingAccessRule','approved_user');  
insert into reservation_rules values(default,'You have not provided sufficient contact information in your profile','SchedulingAccessRule','has_contact_info');  


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

-- add json_cache column to reservations
create table tmp as select * from reservations;
delete from tmp;
alter table tmp add column json_cache text;
alter table tmp add column sent bool;
insert into tmp (id,created_by,aircraft_id,instructor_id,time_start,time_end,reservation_type,json_cache,sent)	
select * from reservations_changes;

drop table reservations_changes;
create table reservations_changes as select * from tmp;
drop table tmp;
alter table reservations add column json_cache text;


commit;