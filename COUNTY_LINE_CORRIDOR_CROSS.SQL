select rl.*
from (select rl.nrlg_dept_route, rl.nrlg_milepoint, rl.nrlg_county,
      lead(rl.nrlg_county) over (partition by rl.nrlg_dept_route
              order by rl.nrlg_milepoint) as next_county
      from tis.tis_new_roadlog rl
     ) rl
where nrlg_county <> next_county
order by nrlg_dept_route

