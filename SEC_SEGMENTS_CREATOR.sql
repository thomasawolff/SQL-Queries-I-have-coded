create or replace view SEC_SEGMENTS_VIEW as
select distinct p.corridor_code_rb,p.road_pathweb,p.van_no,
case when p.beg_gn <> ys.gn_id and p.corridor_code_rb = ys.dc_id and p.begin_mi >= ys.gn_dcmi
  then ys.gn_id
    else p.beg_gn
      end as beg_gn,
case when s.beg_gn is null
  then p.end_gn
    else s.beg_gn
      end as end_gn,
p.corridor_code,p.secfile_name,
p.county_name,p.district_no,p.road_van,p.from_descr,
p.to_descr,p.frfpost,p.trfpost,p.begin_mi,p.end_mi,
p.dir,p.svyleng2012,p.lane,p.rb,
p.start_lat,p.start_lon,p.end_lat,p.end_lon,p.p
from PVMT_EXT_MDT.SEC_SEGMENTS p left join PVMGT_GNs_DCMI_RP_TABLE lb 
on p.corridor_code_rb=lb.corridor_code_rb and p.beg_gn=lb.gn_id
left join PVMGT_GNs_DCMI_RP_TABLE le on p.corridor_code_rb=le.corridor_code_rb and p.beg_gn=le.gn_id
left join GN_DC_LOCATE_JOIN_TABLE ys on ys.gn_id <> p.beg_gn 
and ys.dc_id = p.corridor_code_rb and ys.gn_dcmi = p.begin_mi
left join PVMT_EXT_MDT.SEC_SEGMENTS s
on p.CORRIDOR_CODE_RB = s.CORRIDOR_CODE_RB 
and p.DIR <> s.DIR
and p.BEG_GN <> s.BEG_GN
and p.ROAD_VAN = s.ROAD_VAN
and p.SVYLENG2012 = s.SVYLENG2012
order by 7,p.corridor_code_rb,p.dir DESC,p.lane, p.begin_mi
;
/*select distinct * from PVMT_EXT_MDT.SEC_SEGMENTS z
minus
select distinct t."CORRIDOR_CODE_RB",t."ROAD_PATHWEB",t."VAN_NO",t."BEG_GN",
s."BEG_GN" as END_GN,t."CORRIDOR_CODE",t."SECFILE_NAME",t."COUNTY_NAME",
t."DISTRICT_NO",t."ROAD_VAN",t."FROM_DESCR",t."TO_DESCR",
t."FRFPOST",t."TRFPOST",t."BEGIN_MI",t."END_MI",t."DIR",
t."SVYLENG2012",t."LANE",t."RB",t."START_LAT",t."START_LON",
t."END_LAT",t."END_LON",t."P"
from SEC_SEGMENTS_VIEW t inner join SEC_SEGMENTS_VIEW s
on t."CORRIDOR_CODE_RB" = s."CORRIDOR_CODE_RB" 
and t."DIR" <> s."DIR"
and t."BEG_GN" <> s."BEG_GN"
and t."ROAD_VAN" = s."ROAD_VAN"
and t."SVYLENG2012" = s."SVYLENG2012"
union
select * from SEC_SEGMENTS_VIEW*/
