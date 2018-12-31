           select t.nrlg_dept_route||t.nrlg_dept_roadbed,dt.begmile,dt.endmile
from TIS.TIS_NEW_ROADLOG t
inner join (select d.nrlg_dept_route||d.nrlg_dept_roadbed as corridor,d.nrlg_smaint as maintain,
           min(d.nrlg_dept_length_mi) as begmile,
           sum(d.nrlg_dept_length_mi) as endmile
           from TIS.TIS_NEW_ROADLOG d 
           where d.nrlg_sys_desc not in (select t.nrlg_sys_desc from TIS.TIS_NEW_ROADLOG t
                         where t.nrlg_sys_desc = 'OFF' or t.nrlg_sys_desc = 'OUT' or t.nrlg_sys_desc = 'CLO'
                         group by t.nrlg_sys_desc)
           and d.nrlg_srf_type in (select t.nrlg_srf_type from TIS.TIS_NEW_ROADLOG t where t.nrlg_srf_type = 'PMS'
                         or t.nrlg_srf_type = 'PCC' or t.nrlg_srf_type = 'BST' or t.nrlg_srf_type = 'RMS'
                         group by t.nrlg_srf_type) 
           and d.nrlg_dept_route in (select f.nrlg_dept_route from TIS.TIS_NEW_ROADLOG f 
                                     where f.nrlg_smaint like 'Y' group by f.nrlg_dept_route)
           group by d.nrlg_dept_route||d.nrlg_dept_roadbed,d.nrlg_smaint) dt
on t.nrlg_dept_route||t.nrlg_dept_roadbed = dt.corridor and dt.maintain = t.nrlg_smaint
where t.nrlg_sys_desc is not null and 
t.nrlg_dept_route||t.nrlg_dept_roadbed in (select t.hpms from HPMS_DATA t inner join final_dataset_12174 s 
                                           on t.hpms = s."CORRIDOR_CODE_RB" 
                                           where s."SECFILE_NAME" not like 'North')
group by t.nrlg_dept_route||t.nrlg_dept_roadbed,dt.begmile,dt.endmile
order by 1
