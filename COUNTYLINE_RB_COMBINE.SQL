create or replace view corridor_rb_combined as
select t.corridor,s.corridor_code_rb,t.roadway,
round(cast(s.SVYLENG2012 as float),0)as svylength12,
round(cast(t.frfpost as float),3)as frfpost_short,
round(cast(t.trfpost as float),3)as trfpost_short,lane,t.coll_set,s.dir,t.county_name
from SEC_FILE_05_15_2015 t join files_combined_2015_4 s on
(round(cast(t.frfpost as float),3)) = s.FRFPOST
and (round(cast(s.SVYLENG2012 as float),0)) = t.svylength2012
and t.corridor = s.CORRIDOR_CODE
;
create or replace view county_intersect_corridors as
select distinct roadway,nrlg_dept_route,corridor_code_rb,nrlg_county,next_county,
         round(cast(beg_mi as float),3)as beg_mi,
	 round(cast(end_mi as float),3)as end_mi,
	 (nvl(to_number(miles), 0) + nvl(to_number(fraction), 0)) as milepoint,
	 dir,lane
  from (select regexp_substr(nrlg_milepoint, '[0-9]*') as miles,
	         nrlg_milepoint as nrlg_milepoint,
		 frfpost_short as beg_mi,
		 trfpost_short as end_mi,
		 nrlg_dept_route as nrlg_dept_route,
		 nrlg_county as nrlg_county,
		 next_county as next_county,
		 corridor_code_rb as corridor_code_rb,
		 corridor as corridor_code,
		 dir as dir,
		 lane as lane,
		 roadway as roadway,
               regexp_substr(nrlg_milepoint, '[+-][0-9.]*') as fraction
          from  CORRIDOR_COUNTYLINE_NEW_MILAGE t, corridor_rb_combined s)
	  where nrlg_dept_route = corridor_code
;
create or replace view countyline_data_export asnumber 
select distinct s.roadway,s.nrlg_dept_route,s.corridor_code_rb,s.nrlg_county,s.next_county,
s.beg_mi,s.end_mi,round(cast(s.milepoint as float),3)as countyline,s.dir,s.lane
from county_intersect_corridors s
where s.beg_mi > round(cast(s.milepoint as float),3)
and round(cast(s.milepoint as float),3) < s.end_mi
order by s.nrlg_dept_route,s.beg_mi


