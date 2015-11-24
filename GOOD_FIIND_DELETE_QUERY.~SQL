create or replace table SOUTH_FILES_ROADWAY_DESCR_3
as
(select * from SOUTH_FILES_ROADWAY_DESCR)
;
select * from 
(select svylength
from SOUTH_FILES_ROADWAY_DESCR_3 t
group by svylength
having count(svylength) > 4) 
order by 1
;
delete from SOUTH_FILES_ROADWAY_DESCR_3
where svylength in (select svylength
from SOUTH_FILES_ROADWAY_DESCR_3 t
group by svylength,frfpost_short,trfpost_short
having count(svylength) > 1)
;
alter table SOUTH_FILES_ROADWAY_DESCR_3 add primary key(svylength,frfpost_short,trfpost_short)
;
select * from SOUTH_FILES_ROADWAY_DESCR_3
