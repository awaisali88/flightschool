begin;

-- activity logging 
create table requests(
       id        	 		serial primary key,
       ip_address 			text,
       created_at	 		timestamp,
       http_user_agent	  	text,
       user_id	  			integer,
       http_referer 	 	text,
       request_method  		text,
       request_uri	  		text,
	   request_params		text,	
       request_controller  	text,
       request_action  		text,
       request_id   		text,	
       response_status   	text,
       elapsed_time 		float
);

-- reservation activity logging
create table reservations_audit as select * from reservations;
delete from reservations_audit;
alter table reservations_audit add column modified_at timestamp;

-- trigger to maintain reservations audit table
CREATE OR REPLACE FUNCTION process_reservations_audit() RETURNS TRIGGER AS $reservations_audit$
BEGIN 
INSERT INTO reservations_audit SELECT NEW.*, current_timestamp; 
RETURN NEW; 
END; 
$reservations_audit$ LANGUAGE plpgsql;
            
CREATE TRIGGER reservations_audit 
AFTER INSERT OR UPDATE ON reservations 
FOR EACH ROW EXECUTE PROCEDURE process_reservations_audit();

commit;