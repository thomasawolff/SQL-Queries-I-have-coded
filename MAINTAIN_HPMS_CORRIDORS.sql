select f.corridor_code_rb,s.route_id as HPMS,
dt.roadlog,dt.maintained,dt.descr,
dt.begin_mi,dt.end_mi
from FINAL_DATASET_12174 f
left join HPMS_ALL_CORRIDORS_2 s on f.corridor_code_rb = s.route_id
left join (select t.nrlg_dept_route||t.nrlg_dept_roadbed as roadlog,
          t.nrlg_smaint as maintained,t.nrlg_sys_desc as descr,
          min(t.nrlg_plan_length_mi) as begin_mi,sum(t.nrlg_plan_length_mi) as end_mi
          from TIS.TIS_NEW_ROADLOG t
          where t.nrlg_smaint like 'Y'
          group by t.nrlg_dept_route||t.nrlg_dept_roadbed,
          t.nrlg_smaint,t.nrlg_sys_desc) dt
on f.corridor_code_rb = dt.roadlog
where f.secfile_name <> 'North' and (s.route_id is not null or dt.maintained is not null)
group by f.corridor_code_rb,s.route_id,dt.roadlog,dt.maintained,dt.descr,dt.begin_mi,dt.end_mi
order by 1
