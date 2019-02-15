select distinct
dr.node,p.corridor_code_rb,de.max_end,dr.max_mile,
dr.TIS_XCOORD,dr.TIS_YCOORD
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
group by dr.node,b.gn_id,p.corridor_code_rb,
de.max_end,dr.max_mile,dr.TIS_XCOORD,dr.TIS_YCOORD
order by 2,3


