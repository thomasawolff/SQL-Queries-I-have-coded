create or replace view TRAFFIC_DATA_SUMMARY as
select distinct t.tyc_year,t.tyc_corridor_id||t.tyc_dept_rt_rbd as corridorRB,t.tyc_aadt,
cast(ltrim(substr(t.tyc_dept_rt_milepoint,1,3)||substr(t.tyc_dept_rt_milepoint,-4),'0') as number) as begMi,
cast(ltrim(substr(t.tyc_dept_rt_end_milepoint,1,3)||substr(t.tyc_dept_rt_end_milepoint,-4),'0') as number) as endMi
from TRAFFIC.TRAFFIC_YEARLY_COUNTS t 
group by t.tyc_year,t.tyc_corridor_id,t.tyc_dept_rt_rbd,t.tyc_corridor_id,t.tyc_aadt,
cast(ltrim(substr(t.tyc_dept_rt_milepoint,1,3)||substr(t.tyc_dept_rt_milepoint,-4),'0') as number),
cast(ltrim(substr(t.tyc_dept_rt_end_milepoint,1,3)||substr(t.tyc_dept_rt_end_milepoint,-4),'0') as number)
order by 2,1,4
