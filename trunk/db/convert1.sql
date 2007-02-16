begin;

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
