----------------*************************************************-----------------------------

create or replace view GN_DC_LOCATE as
select distinct t.gn_id, n.tcr_rt||n.tcr_rb as DC_ID,
case when n.beg_brkm<n.end_brkm then
        round(((t.gn_km-n.beg_brkm)+n.beg_tcrkm)*.6213712,3)
   else round(((n.beg_brkm-t.gn_km)+n.beg_tcrkm)*.6213712,3)
    end as GN_DCMI,c.x_coord TIS_XCOORD, c.y_coord TIS_YCOORD
from TIS.TIS_GN_LOCATE t inner join TIS.TIS_TCR_LOOKUP n
on t.route=n.br_id and t.gn_km>=n.beg_abskm and t.gn_km<=n.end_abskm
inner join TIS.TIS_GN_COORDS c on t.gn_id=c.gn_id and n.tcr_rt like 'C%'
;
----------------*************************************************-----------------------------

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
select t.dc_id,t.beg_dcmi,t.end_dcmi,t.dc_rm,
t.beg_dckm,t.end_dckm,t.updt,t.dc_rt,
t.dc_rb,t.rm_virtual,t.alias_rmdc
from TIS.TIS_REF_MARKER_LOOKUP t
;
alter table TIS_REF_MARKER_LOOKUP_TABLE add primary key(dc_id,beg_dcmi,end_dcmi)
;
----------------*************************************************-----------------------------

drop table NEW_CORR_BEG_END_DATA_TABLE
;
create table NEW_CORR_BEG_END_DATA_TABLE as
select s.corridor_code_rb,
s.gn_id as beg_gn,t.gn_id as end_gn,
s.tis_mi as beg_mi,t.tis_mi as end_mi,
s.tis_y as start_lat,s.tis_x as start_long,
t.tis_y as end_lat,t.tis_x as end_long
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
  
----------------*************************************************-----------------------------
/*;
create or replace view PVMGT_SEGS_GNs_DCMI_VIEW as
select * from PVMGT_SEGS_GNs_DCMI_TABLE
UNION
select 999999999999 GN_ID,p.corridor_code_rb, NULL TIS_MI,NULL TIS_X,NULL TIS_Y
from PVMT_EXT_MDT.sec_segments p
where p.beg_gn=999999999999 or p.end_gn=999999999999*/

;
--*** Queries PVMT_EXT_MDT.sec_segments along with the TIS locations in the view PVMGT_GNs_DCMI_RP
create or replace view VAN_DATA_VIEW as
select distinct p.*,
lb.TIS_MI TIS_BEGMI,le.TIS_MI TIS_ENDMI,
lb.TIS_X TIS_STARTX,lb.TIS_Y TIS_STARTY,
le.TIS_X TIS_ENDX,le.TIS_Y TIS_ENDY,
lb.REF_POINT TIS_BEGRP,le.REF_POINT TIS_ENDRP
from PVMT_EXT_MDT.sec_segments p left join PVMGT_GNs_DCMI_RP_TABLE lb 
on p.corridor_code_rb=lb.corridor_code_rb and p.beg_gn=lb.gn_id
left join PVMGT_GNs_DCMI_RP_TABLE le on p.corridor_code_rb=le.corridor_code_rb 
and p.end_gn=le.gn_id
--order by p.corridor_code_rb,p.dir DESC,p.lane, p.begin_mi

----------------*************************************************-----------------------------
;
---*** Queries the roadlog for corridor records 
---on system and paved that are not in van dataset
create or replace view new_coll_corr_1_dont_use as
select concat(t.nrlg_dept_route,t.nrlg_dept_roadbed) as corridor_code_rb
from TIS.TIS_NEW_ROADLOG t
where t.nrlg_srf_type in 'PMS'
and t.nrlg_sys_desc not like 'OFF'
and t.nrlg_sys_desc not like 'OUT'
and t.nrlg_sys_desc not like 'CLO'
or t.nrlg_srf_type in 'PCC'
and t.nrlg_sys_desc not like 'OFF'
and t.nrlg_sys_desc not like 'OUT'
and t.nrlg_sys_desc not like 'CLO'
or t.nrlg_srf_type in 'BST'
and t.nrlg_sys_desc not like 'OFF'
and t.nrlg_sys_desc not like 'OUT'
and t.nrlg_sys_desc not like 'CLO'
or t.nrlg_srf_type in 'RMS'
and t.nrlg_sys_desc not like 'OFF'
and t.nrlg_sys_desc not like 'OUT'
and t.nrlg_sys_desc not like 'CLO'
group by concat(t.nrlg_dept_route,t.nrlg_dept_roadbed)
minus
select s.corridor_code_rb
from PVMT_EXT_MDT.sec_segments s
group by s.corridor_code_rb

----------------*************************************************-----------------------------
;
--*** Combines the view data from above with mile and coordinate data from TIS
create or replace view new_coll_corr_2_dont_use as
select z.corridor_code_rb,
b.gn_id,b.GN_DCMI TIS_MI,
b.TIS_XCOORD TIS_X,
b.TIS_YCOORD TIS_Y
from new_coll_corr_1_dont_use z inner join GN_DC_LOCATE_JOIN_TABLE b
on z.corridor_code_rb=b.DC_ID
union
select z.corridor_code_rb,
e.gn_id,e.GN_DCMI TIS_MI,
e.TIS_XCOORD TIS_X,
e.TIS_YCOORD TIS_Y
from new_coll_corr_1_dont_use z inner join GN_DC_LOCATE_JOIN_TABLE e
on z.corridor_code_rb=e.DC_ID
--order by 1,3

----------------*************************************************-----------------------------
;
--*** Breaks down corridor mile data from above down to just min and max miles
create or replace view new_coll_corr_3_dont_use as
select t.gn_id,t.corridor_code_rb,
t.TIS_MI,t.TIS_X,t.TIS_Y
from new_coll_corr_2_dont_use t
where t.tis_mi = (select min(tis_mi) 
from new_coll_corr_2_dont_use s)
union
select t.gn_id,t.corridor_code_rb,
t.TIS_MI,t.TIS_X,t.TIS_Y
from new_coll_corr_2_dont_use t
inner join (select corridor_code_rb,max(tis_mi) 
     as tis_mi from new_coll_corr_2_dont_use
     group by corridor_code_rb) s
on t.tis_mi = s.tis_mi
--ORDER BY 2,3

----------------*************************************************-----------------------------
;
--*** Finds just the minimum or beginning mile for each new corridor
create or replace view min_mile_new_corr_dont_use as
select gn_id,corridor_code_rb,tis_mi,tis_x,tis_y
from 
 (
   select gn_id,corridor_code_rb,s.tis_mi,tis_x,tis_y,
      ROW_NUMBER()                        
      OVER (PARTITION BY corridor_code_rb 
            ORDER BY s.tis_mi ASC) AS rn 
      from new_coll_corr_3_dont_use s
 ) dt
WHERE rn = 1 

----------------*************************************************-----------------------------
;
--*** Finds just the maximum or ending mile for each new corridor
create or replace view max_mile_new_corr_dont_use as
select gn_id,corridor_code_rb,tis_mi,tis_x,tis_y
from 
 (
   select gn_id,corridor_code_rb,s.tis_mi,tis_x,tis_y,
      ROW_NUMBER()                        
      OVER (PARTITION BY corridor_code_rb 
            ORDER BY s.tis_mi DESC) AS rn 
      from new_coll_corr_3_dont_use s
 ) dt
WHERE rn = 1 

----------------*************************************************-----------------------------
;
---*** Creates the final dataset for new corridors to be included
create or replace view DATASET_NEW_CORRIDORS as
select distinct t.beg_gn,t.end_gn,
n.nrlg_dept_route as corridor_code,
t.corridor_code_rb,
n.nrlg_rte_name as road_pathweb,
n.nrlg_county as county_name,
t.beg_mi,t.end_mi,
t.start_long,t.start_lat,
t.end_long,t.end_lat,
n.nrlg_dept_roadbed as rb,
n.nrlg_srf_type as p,
n.nrlg_fdist as district_no
from NEW_CORR_BEG_END_DATA_TABLE t
inner join TIS.TIS_NEW_ROADLOG n on 
t.corridor_code_rb=concat(n.nrlg_dept_route,n.nrlg_dept_roadbed)
where n.nrlg_srf_type not like 'GRV'
and t.corridor_code_rb not like 'C003102N'
and t.corridor_code_rb not like 'C000422N'
--order by 1

----------------*************************************************-----------------------------
;
---*** Creates increasing data record for missing corridors
create or replace view final_corrs_all_rows_inc as
select t.corridor_code_rb,
null as road_pathweb,
null as van_no,
t.beg_gn,t.end_gn,
t.corridor_code,
null as secfile_name,
t.county_name,
cast(t.district_no as number) as district_no,
t.road_pathweb as road_van,
null as from_descr,
null as to_descr,
t.beg_mi as frfpost,
t.end_mi as trfpost,
t.beg_mi,t.end_mi,
null as dir,
null as svyleng2012,
null as lane,t.rb,
t.start_lat,
t.start_long,
t.end_lat,
t.end_long,
t.p from DATASET_NEW_CORRIDORS t

----------------*************************************************-----------------------------
;
---*** Creates decreasing data record for missing corridors
create or replace view final_corrs_all_rows_dec as
select t.corridor_code_rb,
null as road_pathweb,
null as van_no,
t.end_gn as beg_gn,
t.beg_gn as end_gn,
t.corridor_code,
null as secfile_name,
t.county_name,
cast(t.district_no as number) as district_no,
t.road_pathweb as road_van,
null as from_descr,
null as to_descr,
t.end_mi as frfpost,
t.beg_mi as trfpost,
t.end_mi as begin_mi,
t.beg_mi as end_mi,
null as dir,
null as svyleng2012,
null as lane,t.rb,
t.end_lat as start_lat,
t.end_long as start_long,
t.start_lat as end_lat,
t.start_long as end_long,
t.p from DATASET_NEW_CORRIDORS t

----------------*************************************************-----------------------------
;
---*** Combines increasing and decreasing records into one dataset
create or replace view NEW_SEGMENTS_DATA_VIEW as
select *
from final_corrs_all_rows_inc t
union 
select *
from final_corrs_all_rows_dec s

----------------*************************************************-----------------------------
;
---*** Filters out the forest roads from the final collection dataset for van 12174
create or replace view FINAL_DATASET_12174 as
select s.*,
abs(s.BEGIN_MI - s.TIS_BEGMI) as begDiff,
abs(s.end_MI - s.TIS_ENDMI) as endDiff
from VAN_DATA_VIEW s
where s.VAN_NO = 12174
and s.CORRIDOR_CODE not like 'C901002'
and s.ROAD_VAN not like '%Ant Flat Road%'
minus
select s.*, 
abs(s.BEGIN_MI - s.TIS_BEGMI) as begDiff,
abs(s.end_MI - s.TIS_ENDMI) as endDiff
from VAN_DATA_VIEW s inner join forest_highways_hwy_table t
on s.CORRIDOR_CODE like 'C0'||t.Corridor
where s.VAN_NO = 12174 and t.Corridor > 600
order by 3,7,1,17 desc,19,15

----------------*************************************************-----------------------------
;
---*** Filters out the forest roads from the final collection dataset for van 12175
create or replace view FINAL_DATASET_12175 as
select s.*, 
abs(s.BEGIN_MI - s.TIS_BEGMI) as begDiff,
abs(s.end_MI - s.TIS_ENDMI) as endDiff
from VAN_DATA_VIEW s
where s.VAN_NO = 12175
and s.CORRIDOR_CODE not like 'C901002'
and s.ROAD_VAN not like '%Ant Flat Road%'
minus
select s.*,
abs(s.BEGIN_MI - s.TIS_BEGMI) as begDiff,
abs(s.end_MI - s.TIS_ENDMI) as endDiff
from VAN_DATA_VIEW s inner join forest_highways_hwy_table t
on s.CORRIDOR_CODE like 'C0'||t.Corridor
where s.VAN_NO = 12175 and t.Corridor > 600
order by 3,7,1,17 desc,19,15
;
----------------*************************************************-----------------------------
