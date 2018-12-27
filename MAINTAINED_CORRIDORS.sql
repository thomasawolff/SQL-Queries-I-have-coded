select t.nrlg_dept_route,dt.begmile,dt.endmile
from TIS.TIS_NEW_ROADLOG t
inner join (select d.nrlg_dept_route as corridor,
           min(d.nrlg_dept_length_mi) as begmile,
           sum(d.nrlg_dept_length_mi) as endmile
           from TIS.TIS_NEW_ROADLOG d 
           group by d.nrlg_dept_route) dt
on t.nrlg_dept_route = dt.corridor
where t.nrlg_dept_route in 
(select s.nrlg_dept_route from TIS.TIS_NEW_ROADLOG s where s.nrlg_smaint like 'Y') 
and t.nrlg_sys_desc is not null
and t.nrlg_sys_desc not in (select t.nrlg_sys_desc from TIS.TIS_NEW_ROADLOG t
                         where t.nrlg_sys_desc = 'OFF' or t.nrlg_sys_desc = 'OUT' or t.nrlg_sys_desc = 'CLO'
                         group by t.nrlg_sys_desc)
and t.nrlg_srf_type in (select t.nrlg_srf_type from TIS.TIS_NEW_ROADLOG t where t.nrlg_srf_type = 'PMS'
                         or t.nrlg_srf_type = 'PCC' or t.nrlg_srf_type = 'BST' or t.nrlg_srf_type = 'RMS'
                         group by t.nrlg_srf_type) 
group by t.nrlg_dept_route,dt.begmile,dt.endmile
order by 1
