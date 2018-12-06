
--*** Creates a VIEW of all TIS GN's with their Corridor ID, Accum Mile and XY coords
create or replace view GN_DC_LOCATE_PRE as
select distinct t.gn_id, n.tcr_rt||n.tcr_rb as DC_ID,
        case when n.beg_brkm<n.end_brkm then
                  round(((t.gn_km-n.beg_brkm)+n.beg_tcrkm)*.6213712,3)
             else round(((n.beg_brkm-t.gn_km)+n.beg_tcrkm)*.6213712,3)
              end as GN_DCMI,c.x_coord as TIS_XCOORD, c.y_coord as TIS_YCOORD
from tis.tis_gn_locate t,tis.tis_tcr_lookup n,tis.tis_gn_coords c
where t.route=n.br_id and t.gn_km>=n.beg_abskm and t.gn_km<=n.end_abskm
and t.gn_id=c.gn_id and n.tcr_rt like 'C%'
;
create or replace view GN_DC_LOCATE as 
select t.gn_id,t.DC_ID,t.GN_DCMI,t.TIS_XCOORD,t.TIS_YCOORD 
from GN_DC_LOCATE_PRE t inner join GN_DC_LOCATE_PRE s
on t.gn_id = s.gn_id and t.DC_ID = s.DC_ID
group by t.gn_id,t.DC_ID,t.GN_DCMI,t.TIS_XCOORD,t.TIS_YCOORD
having count(t.gn_id)=1 and count(t.DC_ID)=1
;
--*** Creates a VIEW of all begin and end GN's on PVMT_EXT_MDT.sec_segments
 --from the view GN_DC_LOCATE and adds in the records where GN=999999999999
create or replace view PVMGT_SEGS_GNs_DCMI as
select p.corridor_code_rb,
       b.gn_id,b.GN_DCMI TIS_MI,
       b.TIS_XCOORD TIS_X,b.TIS_YCOORD TIS_Y
from PVMT_EXT_MDT.sec_segments p left join GN_DC_LOCATE b
on p.corridor_code_rb=b.DC_ID and p.beg_gn=b.gn_id
UNION
select p.corridor_code_rb,
       e.gn_id,e.GN_DCMI TIS_MI,e.TIS_XCOORD TIS_X,e.TIS_YCOORD TIS_Y
from PVMT_EXT_MDT.sec_segments p left join GN_DC_LOCATE e
on p.corridor_code_rb=e.DC_ID and p.end_gn=e.gn_id
UNION
select p.corridor_code_rb,999999999999 GN_ID, NULL TIS_MI,NULL TIS_X,NULL TIS_Y
from PVMT_EXT_MDT.sec_segments p
where p.beg_gn=999999999999 or p.end_gn=999999999999
--order by 1,3
;
create or replace view PVMGT_SEGS_GNs_DCMI_VIEW as
select * from PVMGT_SEGS_GNs_DCMI
UNION
select p.corridor_code_rb,999999999999 GN_ID, NULL TIS_MI,NULL TIS_X,NULL TIS_Y
from PVMT_EXT_MDT.sec_segments p
where p.beg_gn=999999999999 or p.end_gn=999999999999
--order by 1,2
;
--*** Creates a VIEW of all said GN's with their Reference Points
-- and adds in the records where GN=999999999999
create or replace view PVMGT_GNs_DCMI_RP as
select distinct t.corridor_code_rb,t.gn_id,t.TIS_MI,t.TIS_X,t.TIS_Y,
to_char(max(b.dc_rm),'009')||'+'||ltrim(to_char(min(t.TIS_MI-b.beg_dcmi),'0.999')) REF_POINT
from PVMGT_SEGS_GNs_DCMI_VIEW t inner join PVMT_EXT_MDT.TIS_REF_MARKER_LOOKUP_TABLE b
on t.corridor_code_rb=b.dc_id and t.TIS_MI>=b.beg_dcmi and t.TIS_MI<=b.end_dcmi
group by t.corridor_code_rb,t.gn_id,t.TIS_MI,t.TIS_X,t.TIS_Y
UNION
select v.*, NULL REF_POINT
from PVMGT_SEGS_GNs_DCMI v
where v.gn_id=999999999999
--order by corridor_code_rb,TIS_MI
;
--*** Queries PVMT_EXT_MDT.sec_segments along with the TIS locations in the view PVMGT_GNs_DCMI_RP
create or replace view VAN_DATA_VIEW as
select distinct p.*,
       lb.TIS_MI TIS_BEGMI,le.TIS_MI TIS_ENDMI,
       lb.TIS_X TIS_STARTX,lb.TIS_Y TIS_STARTY,
       le.TIS_X TIS_ENDX,le.TIS_Y TIS_ENDY,
       --lb.REF_POINT TIS_BEGRP,le.REF_POINT TIS_ENDRP,
       cast(concat((substr(lb.REF_POINT,0,4)),substr(lb.REF_POINT,7,9)) as number) as TIS_BEGRP,
       cast(concat((substr(le.REF_POINT,0,4)),substr(le.REF_POINT,7,9)) as number) as TIS_ENDRP
from PVMT_EXT_MDT.sec_segments p left join PVMGT_GNs_DCMI_RP lb 
on p.corridor_code_rb=lb.corridor_code_rb and p.beg_gn=lb.gn_id
left join PVMGT_GNs_DCMI_RP le on p.corridor_code_rb=le.corridor_code_rb 
and p.end_gn=le.gn_id
--order by p.corridor_code_rb,p.dir DESC,p.lane, p.begin_mi
;
---*** Queries the roadlog for corridor records 
---on system and paved that are not in van dataset
create or replace view new_coll_corr_1_dont_use as
select distinct concat(t.nrlg_dept_route,t.nrlg_dept_roadbed) as corridor_code_rb
from TIS.TIS_NEW_ROADLOG t
where t.nrlg_srf_type in (select t.nrlg_srf_type from TIS.TIS_NEW_ROADLOG t where t.nrlg_srf_type = 'PMS'
                         or t.nrlg_srf_type = 'PCC' or t.nrlg_srf_type = 'BST' or t.nrlg_srf_type = 'RMS'
                         group by t.nrlg_srf_type) 
and t.nrlg_sys_desc not in (select t.nrlg_sys_desc from TIS.TIS_NEW_ROADLOG t
                         where t.nrlg_sys_desc = 'OFF' or t.nrlg_sys_desc = 'OUT' or t.nrlg_sys_desc = 'CLO'
                         group by t.nrlg_sys_desc)
minus
select s.corridor_code_rb
from PVMT_EXT_MDT.sec_segments s
;
--*** Combines the view data from above with mile and coordinate data from TIS
create or replace view new_coll_corr_2_dont_use as
select z.corridor_code_rb,
       b.gn_id,b.GN_DCMI TIS_MI,
       b.TIS_XCOORD TIS_X,
       b.TIS_YCOORD TIS_Y
from new_coll_corr_1_dont_use z inner join GN_DC_LOCATE b
on z.corridor_code_rb=b.DC_ID
union
select z.corridor_code_rb,
       e.gn_id,e.GN_DCMI TIS_MI,
       e.TIS_XCOORD TIS_X,
       e.TIS_YCOORD TIS_Y
from new_coll_corr_1_dont_use z inner join GN_DC_LOCATE e
on z.corridor_code_rb=e.DC_ID
--order by 1,3
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
;
---*** Creates the final dataset for new corridors to be included
create or replace view DATASET_NEW_CORRIDORS as
select distinct s.gn_id as beg_gn,t.gn_id as end_gn,
n.nrlg_dept_route as corridor_code,
s.corridor_code_rb,
n.nrlg_rte_name as road_pathweb,
n.nrlg_county as county_name,
s.tis_mi as begin_mi,
t.tis_mi as end_mi,
s.tis_x as start_lon,
s.tis_y as start_lat,
t.tis_x as end_lon,
t.tis_y as end_lat,
n.nrlg_dept_roadbed as rb,
n.nrlg_srf_type as p,
n.nrlg_fdist as district_no
from min_mile_new_corr_dont_use s 
inner join max_mile_new_corr_dont_use t on
s.corridor_code_rb = t.corridor_code_rb 
inner join TIS.TIS_NEW_ROADLOG n on 
t.corridor_code_rb=concat(n.nrlg_dept_route,n.nrlg_dept_roadbed)
where n.nrlg_srf_type not like 'GRV'
and t.corridor_code_rb not like 'C003102N'
and t.corridor_code_rb not like 'C000422N'
--order by 1
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
--t.road_pathweb as road_van,
null as road_van,
null as from_descr,
null as to_descr,
t.begin_mi as frfpost,
t.end_mi as trfpost,
t.begin_mi,t.end_mi,
null as dir,
null as svyleng2012,
null as lane,t.rb,
t.start_lat,
t.start_lon,
t.end_lat,
t.end_lon,
null as p
from DATASET_NEW_CORRIDORS t
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
--t.road_pathweb as road_van,
null as road_van,
null as from_descr,
null as to_descr,
t.end_mi as frfpost,
t.begin_mi as trfpost,
t.end_mi as begin_mi,
t.begin_mi as end_mi,
null as dir,
null as svyleng2012,
null as lane,t.rb,
t.end_lat as start_lat,
t.end_lon as start_lon,
t.start_lat as end_lat,
t.start_lon as end_lon,
null as p
from DATASET_NEW_CORRIDORS t
;
---*** Combines increasing and decreasing records into one dataset
create or replace view NEW_SEGMENTS_DATA_VIEW as
select *
from final_corrs_all_rows_inc t
union 
select *
from final_corrs_all_rows_dec s
;

---*** Filters out the forest roads from the final collection dataset for van 12174
create or replace view FINAL_DATASET_12174 as
select s.*
from VAN_DATA_VIEW s
where s.VAN_NO = 12174
and s.CORRIDOR_CODE not like 'C901002'
and s.ROAD_VAN not like '%Ant Flat Road%'
minus
select s.* 
from VAN_DATA_VIEW s inner join PVMT_EXT_MDT.forest_highways_hwy_table t
on s.CORRIDOR_CODE like 'C0'||t.Corridor
where s.VAN_NO = 12174 and t.Corridor > 600
order by 3,7,1,17 desc,19,15
;
---*** Filters out the forest roads from the final collection dataset for van 12175
create or replace view FINAL_DATASET_12175 as
select s.*
from VAN_DATA_VIEW s
where s.VAN_NO = 12175
and s.CORRIDOR_CODE not like 'C901002'
and s.ROAD_VAN not like '%Ant Flat Road%'
minus
select s.*
from VAN_DATA_VIEW s inner join PVMT_EXT_MDT.forest_highways_hwy_table t
on s.CORRIDOR_CODE like 'C0'||t.Corridor
where s.VAN_NO = 12175 and t.Corridor > 600
order by 3,7,1,17 desc,19,15



