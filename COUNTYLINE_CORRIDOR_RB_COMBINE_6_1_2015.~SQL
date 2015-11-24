create or replace view corridor_rb_combined as
select t.corridor,s.corridor_code_rb,t.roadway
,s.start_lat,s.start_lon,
round(cast(s.SVYLENG2012 as float),0)as svylength12,
round(cast(t.frfpost as float),3)as frfpost_short,
round(cast(t.trfpost as float),3)as trfpost_short,lane,t.coll_set
from SEC_FILE_05_15_2015 t join files_combined_2015_4 s on
(round(cast(t.frfpost as float),3)) = s.FRFPOST
and (round(cast(s.SVYLENG2012 as float),0)) = t.svylength2012
and t.corridor = s.CORRIDOR_CODE
;
create or replace view county_intersect_corridors as
select distinct nrlg_dept_route,nrlg_county,next_county,
       nvl(to_number(miles), 0) + nvl(to_number(fraction), 0) as milepoint
       from (select regexp_substr(nrlg_milepoint, '[0-9]*') as miles,
          nrlg_milepoint as nrlg_milepoint,
          nrlg_dept_route as nrlg_dept_route, 
          nrlg_county as nrlg_county,
          next_county as next_county,
          corridor as corridor_code,
	  start_lat as start_lat,
	  start_lon as start_long,
	  svylength12 as svylength,
          regexp_substr(nrlg_milepoint, '[+-][0-9.]*') as fraction
          from corridor_county_intersect s, corridor_rb_combined t)
          	where nrlg_dept_route = corridor_code
;
create or replace view county_line_point_corridors as
select s.roadway,s.corridor,s.corridor_code_rb,s.frfpost_short,
s.trfpost_short,t.milepoint,t.nrlg_county,t.next_county
from COUNTY_INTERSECT_CORRIDORS t join corridor_rb_combined s on
t.milepoint > s.frfpost_short
and t.milepoint < s.trfpost_short
and t.nrlg_dept_route = s.corridor
and abs(s.frfpost_short - t.milepoint) > 2.00
order by t.nrlg_dept_route,s.frfpost_short,t.milepoint
;
/*select s.roadway,s.corridor,t.frfpost_short,t.trfpost_short,s.milepoint,
s.nrlg_county,s.next_county,s.svylength,t.lane
from corridor_rb_combined t join county_line_point_corridors s on s.svylength = t.svylength12
order by 2,3,4,5*/

