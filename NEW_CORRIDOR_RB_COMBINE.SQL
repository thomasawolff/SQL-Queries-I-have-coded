--create or replace view export_07_16_2015_north as
/*select distinct s.corridor_code,
s.corridor_code_rb,
w.road_van,
w.from_descr,
w.to_descr,
t.coll_set,
t.lane,
t.direction,
round(cast(s.svylength as float),0)as svylength,
round(cast(t.frfpost as float),4)as frfpost_short,
round(cast(t.trfpost as float),4)as trfpost_short
from SEC_FILE_08_07_15_NORTH t 

inner join north_files_corr_rb s 
on ((round(cast(t.frfpost as float),4)) = s.frfpost_short
and (round(cast(s.svylength as float),0)) = t.seg_length) 

inner join north_files_roadway_descr w
on w.frfpost_short = s.frfpost_short
and w.svylength = s.svylength

order by corridor_code,frfpost_short*/

--create or replace view export_07_28_2015_south as
select s.corridor_code,
s.corridor_code_rb,
w.road_van,
w.from_descr,
w.to_descr,
t.coll_set,
t.direction,
t.lane,
round(cast(s.svylength as float),0)as svylength,
round(cast(t.frfpost as float),3)as frfpost_short,
round(cast(t.trfpost as float),3)as trfpost_short
from SEC_FILE_09_04_15_SOUTH t 

inner join south_files_corr_rb s 
on (round(cast(t.frfpost as float),3)) = s.frfpost_short
and (round(cast(t.trfpost as float),3)) = s.trfpost_short
and (round(cast(s.svylength as float),0)) = t.seg_length

inner join south_files_roadway_descr w 
on (round(cast(t.frfpost as float),3)) = w.frfpost_short
and (round(cast(t.trfpost as float),3)) = w.trfpost_short
and (round(cast(w.svylength as float),0)) = t.seg_length

order by s.corridor_code,frfpost_short



