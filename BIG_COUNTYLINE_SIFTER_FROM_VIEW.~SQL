select distinct nrlg_dept_route,corridor_code_rb,nrlg_county,next_county,lane,
       nvl(to_number(miles), 0) + nvl(to_number(fraction), 0) as milepoint
  from (select regexp_substr(nrlg_milepoint, '[0-9]*') as miles,
	             nrlg_milepoint as nrlg_milepoint,
		     nrlg_dept_route as nrlg_dept_route,
		     nrlg_county as nrlg_county,
		     next_county as next_county,
		     corridor_code_rb as corridor_code_rb,
		     corridor_code as corridor_code,
		     dir as dir,
		     lane as lane,
               	     regexp_substr(nrlg_milepoint, '[+-][0-9.]*') as fraction
          from corridor_county_intersect,south_van_data_view)
			where nrlg_dept_route = corridor_code
			and corridor_code = 'C000023'
			and dir = 'I'
			order by 1,6			
