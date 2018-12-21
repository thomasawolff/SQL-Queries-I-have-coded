select t."SECFILE_NAME",count(t."CORRIDOR_CODE") as Total,dt.total_miles,'North'
from FINAL_DATASET_12174 t
inner join (select s.SECFILE_NAME,sum(abs(s."END_MI"-s."BEGIN_MI")) as total_miles 
                                      from FINAL_DATASET_12174 s
                                      group by s.SECFILE_NAME) dt        
on t.SECFILE_NAME = dt.secfile_name
where t."SECFILE_NAME" not like 'North'
and t."SECFILE_NAME" not like 'Non%'
and t."DIR" = 'I' and t."LANE" = 1
group by t.SECFILE_NAME,dt.total_miles 
having count(t."CORRIDOR_CODE") > 1 
union
select t."SECFILE_NAME",count(t."CORRIDOR_CODE") as Total,dt.total_miles,'South'
from FINAL_DATASET_12175 t
inner join (select s.SECFILE_NAME,sum(abs(s."END_MI"-s."BEGIN_MI")) as total_miles 
                                      from FINAL_DATASET_12175 s
                                      group by s.SECFILE_NAME) dt        
on t.SECFILE_NAME = dt.secfile_name
where t."SECFILE_NAME" not like 'South'
and t."SECFILE_NAME" not like 'Non%'
and t."DIR" = 'I' and t."LANE" = 1
group by t.SECFILE_NAME,dt.total_miles 
having count(t."CORRIDOR_CODE") > 1 
order by 4

