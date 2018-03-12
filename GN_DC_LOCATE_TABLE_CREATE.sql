
drop table GN_DC_LOCATE_TABLE
;
create table GN_DC_LOCATE_TABLE as
select t.gn_id,t.DC_ID
from GN_DC_LOCATE t 
where (t.gn_id) is not null 
and (t.DC_ID) is not null
group by t.gn_id,t.DC_ID
having count(*) = 1
;
alter table GN_DC_LOCATE_TABLE add primary key(gn_id,dc_id)
;
----------------*************************************************-----------------------------

drop table GN_DC_LOCATE_JOIN_TABLE
;
create table GN_DC_LOCATE_JOIN_TABLE as
select s.* from GN_DC_LOCATE_TABLE t inner join GN_DC_LOCATE s
on t.gn_id = s.gn_id and t.dc_id = s.DC_ID 
;
alter table GN_DC_LOCATE_JOIN_TABLE add primary key(gn_id,dc_id)
;
----------------*************************************************-----------------------------

drop table PVMGT_SEGS_GNs_DCMI_TABLE
;
create table PVMGT_SEGS_GNs_DCMI_TABLE as
select b.gn_id,p.corridor_code_rb,
       b.GN_DCMI TIS_MI,
       b.TIS_XCOORD TIS_X,b.TIS_YCOORD TIS_Y
from PVMT_EXT_MDT.SEC_SEGMENTS p left join GN_DC_LOCATE_JOIN_TABLE b
on p.corridor_code_rb=b.DC_ID and p.beg_gn=b.gn_id
where b.gn_id is not null
UNION
select e.gn_id,p.corridor_code_rb,
       e.GN_DCMI TIS_MI,e.TIS_XCOORD TIS_X,e.TIS_YCOORD TIS_Y
from PVMT_EXT_MDT.SEC_SEGMENTS p left join GN_DC_LOCATE_JOIN_TABLE e
on p.corridor_code_rb=e.DC_ID and p.end_gn=e.gn_id
where e.gn_id is not null
order by 1,2
;
alter table PVMGT_SEGS_GNs_DCMI_TABLE add primary key(gn_id,corridor_code_rb)
;
----------------*************************************************-----------------------------

drop table PVMGT_GNS_DCMI_RP_TABLE
;
create table PVMGT_GNS_DCMI_RP_TABLE as
select distinct t.corridor_code_rb,t.gn_id,t.TIS_MI,t.TIS_X,t.TIS_Y,
to_char(max(b.dc_rm),'009')||'+'||ltrim(to_char(min(t.TIS_MI-b.beg_dcmi),'0.999')) REF_POINT
from PVMGT_SEGS_GNs_DCMI_TABLE t inner join TIS_REF_MARKER_LOOKUP_TABLE b
on t.corridor_code_rb=b.dc_id and t.TIS_MI>=b.beg_dcmi and t.TIS_MI<=b.end_dcmi
group by t.corridor_code_rb,t.gn_id,t.TIS_MI,t.TIS_X,t.TIS_Y
;
alter table PVMGT_GNS_DCMI_RP_TABLE add primary key(GN_ID,CORRIDOR_CODE_RB)
;
----------------*************************************************-----------------------------

drop table TIS_REF_MARKER_LOOKUP_TABLE
;
create table TIS_REF_MARKER_LOOKUP_TABLE as
select t.dc_id,
       t.beg_dcmi,
       t.end_dcmi,
       t.dc_rm,
       t.beg_dckm,
       t.end_dckm,
       t.updt,
       t.dc_rt,
       t.dc_rb,
       t.rm_virtual,
       t.alias_rmdc
       from TIS.TIS_REF_MARKER_LOOKUP t
;
alter table TIS_REF_MARKER_LOOKUP_TABLE add primary key(dc_id,beg_dcmi,end_dcmi)
;
----------------*************************************************-----------------------------

drop table NEW_CORR_BEG_END_DATA_TABLE
;
create table NEW_CORR_BEG_END_DATA_TABLE as
select s.corridor_code_rb,
       s.gn_id as beg_gn,
       t.gn_id as end_gn,
       s.tis_mi as beg_mi,
       t.tis_mi as end_mi,
       s.tis_y as start_lat,
       s.tis_x as start_long,
       t.tis_y as end_lat,
       t.tis_x as end_long
from min_mile_new_corr_dont_use s 
inner join max_mile_new_corr_dont_use t 
on s.corridor_code_rb = t.corridor_code_rb
;
alter table NEW_CORR_BEG_END_DATA_TABLE add primary key(corridor_code_rb)
;
----------------*************************************************-----------------------------

drop table FOREST_HIGHWAYS_HWY_TABLE
;
create table FOREST_HIGHWAYS_HWY_TABLE as
select cast(t.tfh_route as number) as Corridor
from TIS.TIS_FOREST_HIGHWAYS_TEMP t
group by t.tfh_route
order by 1
;
alter table forest_highways_hwy_table add primary key(Corridor);
  
