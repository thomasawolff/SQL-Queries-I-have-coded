select distinct
p.corridor_code_rb,p.road_pathweb,p.van_no,
null as beg_gn,dr.node as end_gn,p.corridor_code,
p.secfile_name,null as county_name,null as district_no,
p.road_van,null as from_descr,null as to_descr,
null as frfpost,null as trfpost,
de.max_end as begin_mi,dr.max_mile as end_mi,
null as dir,null as svyleng2012,null as lane,null as rb,
null as start_lat,null as start_lon,
dr.TIS_XCOORD as end_lat,dr.TIS_YCOORD as end_lon,null as p
from PVMT_EXT_MDT.sec_segments p 
inner join GN_DC_LOCATE b 
on p.corridor_code_rb=b.DC_ID and p.beg_gn=b.gn_id 
inner join (select t.DC_ID as corridor, 
           --min(t.GN_DCMI) as min_mile,
           max(t.GN_DCMI) as max_mile
           from GN_DC_LOCATE t 
           group by t.DC_ID) dt
on dt.corridor = p.corridor_code_rb
inner join (select t.gn_id as node,
           t.DC_ID as corridor, 
           --min(t.GN_DCMI) as min_mile,
           max(t.GN_DCMI) as max_mile,
           t.TIS_XCOORD,t.TIS_YCOORD
           from GN_DC_LOCATE t 
           group by t.gn_id,t.DC_ID,
           t.TIS_XCOORD,t.TIS_YCOORD) dr
on dr.corridor = p.corridor_code_rb
and dr.max_mile = dt.max_mile
inner join (select d.corridor_code_rb,max(d.end_mi) as max_end 
           from PVMT_EXT_MDT.sec_segments d group by d.corridor_code_rb) de
on p.corridor_code_rb = de.corridor_code_rb
where p.secfile_name like '%North%'
and p.dir like 'I' and de.max_end <> dt.max_mile 
and p.to_descr not like '%Gravel%'
group by p.corridor_code_rb,p.road_pathweb,p.van_no,p.beg_gn,dr.node,
p.corridor_code,p.secfile_name,p.county_name,p.district_no,
p.road_van,p.from_descr,p.to_descr,p.frfpost,p.trfpost,
de.max_end,dr.max_mile,p.dir,p.svyleng2012,p.lane,p.rb,
p.start_lat,p.start_lon,dr.TIS_XCOORD,dr.TIS_YCOORD,p
order by 1


