--*** Creates a VIEW of all TIS GN's with their Corridor ID, Accum Mile and XY coords
create or replace view GN_DC_LOCATE as
select distinct t.gn_id, n.tcr_rt||n.tcr_rb DC_ID,
        case when n.beg_brkm<n.end_brkm then
                  round(((t.gn_km-n.beg_brkm)+n.beg_tcrkm)*.6213712,3)
             else round(((n.beg_brkm-t.gn_km)+n.beg_tcrkm)*.6213712,3)
              end as GN_DCMI,c.x_coord TIS_XCOORD, c.y_coord TIS_YCOORD
from tis.tis_gn_locate t,tis.tis_tcr_lookup n,tis.tis_gn_coords c
where t.route=n.br_id and t.gn_km>=n.beg_abskm and t.gn_km<=n.end_abskm
      and t.gn_id=c.gn_id
;
--*** Creates a VIEW of all begin and end GN's on ops$u2970.sec_segments
   --from the view GN_DC_LOCATE and adds in the records where GN=999999999999
create or replace view PVMGT_SEGS_GNs_DCMI as
select p.corridor_code_rb,
       b.gn_id,b.GN_DCMI TIS_MI,
       b.TIS_XCOORD TIS_X,b.TIS_YCOORD TIS_Y
from ops$u2970.sec_segments p, GN_DC_LOCATE b
where p.corridor_code_rb=b.DC_ID and p.beg_gn=b.gn_id
UNION
select p.corridor_code_rb,
       e.gn_id,e.GN_DCMI TIS_MI,e.TIS_XCOORD TIS_X,e.TIS_YCOORD TIS_Y
from ops$u2970.sec_segments p,GN_DC_LOCATE e
where p.corridor_code_rb=e.DC_ID and p.end_gn=e.gn_id
UNION
select p.corridor_code_rb,999999999999 GN_ID, NULL TIS_MI,NULL TIS_X,NULL TIS_Y
from ops$u2970.sec_segments p
where p.beg_gn=999999999999 or p.end_gn=999999999999
order by 1,3
;
--*** Creates a VIEW of all said GN's with their Reference Points
-- and adds in the records where GN=999999999999
create or replace view PVMGT_GNs_DCMI_RP as
select t.corridor_code_rb,t.gn_id,t.TIS_MI,t.TIS_X,t.TIS_Y,
to_char(max(b.dc_rm),'009')||'+'||ltrim(to_char(min(t.TIS_MI-b.beg_dcmi),'0.999')) REF_POINT
from PVMGT_SEGS_GNs_DCMI t,tis.tis_ref_marker_lookup b
where t.corridor_code_rb=b.dc_id and t.TIS_MI>=b.beg_dcmi and t.TIS_MI<=b.end_dcmi
group by t.corridor_code_rb,t.gn_id,t.TIS_MI,t.TIS_X,t.TIS_Y
UNION
select v.*, NULL REF_POINT
from PVMGT_SEGS_GNs_DCMI v
where v.gn_id=999999999999
order by corridor_code_rb,TIS_MI
;
--*** Queries ops$u2970.sec_segments along with the TIS locations in the view PVMGT_GNs_DCMI_RP
create or replace view VAN_DATA_VIEW as
select p.*,
       lb.TIS_MI TIS_BEGMI,le.TIS_MI TIS_ENDMI,
       lb.TIS_X TIS_STARTX,lb.TIS_Y TIS_STARTY,
       le.TIS_X TIS_ENDX,le.TIS_Y TIS_ENDY,
       lb.REF_POINT TIS_BEGRP,le.REF_POINT TIS_ENDRP
from ops$u2970.sec_segments p left join PVMGT_GNs_DCMI_RP lb 
on p.corridor_code_rb=lb.corridor_code_rb and p.beg_gn=lb.gn_id
left join PVMGT_GNs_DCMI_RP le
on p.corridor_code_rb=le.corridor_code_rb and p.end_gn=le.gn_id
order by p.corridor_code_rb,p.dir DESC,p.lane, p.begin_mi
;
---*** Queries the roadlog for corridor records 
---on system and paved that are not in van dataset
create or replace view new_coll_corr_1_dont_use as
select distinct concat(t.nrlg_dept_route,t.nrlg_roadbed) as corridor_code_rb
from TIS.TIS_NEW_ROADLOG t
where t.nrlg_srf_type like 'PMS'
and t.nrlg_sys_desc not like 'OFF'
and t.nrlg_sys_desc not like 'OUT'
and t.nrlg_sys_desc not like 'CLO'
or t.nrlg_srf_type like 'PCC'
and t.nrlg_sys_desc not like 'OFF'
and t.nrlg_sys_desc not like 'OUT'
and t.nrlg_sys_desc not like 'CLO'
or t.nrlg_srf_type like 'BST'
and t.nrlg_sys_desc not like 'OFF'
and t.nrlg_sys_desc not like 'OUT'
and t.nrlg_sys_desc not like 'CLO'
or t.nrlg_srf_type like 'RMS'
and t.nrlg_sys_desc not like 'OFF'
and t.nrlg_sys_desc not like 'OUT'
and t.nrlg_sys_desc not like 'CLO'
minus
select s.corridor_code_rb
from ops$u2970.sec_segments s
order by 1
;
--*** Combines the view data from above with mile and coordinate data from TIS
create or replace view new_coll_corr_2_dont_use as
select z.corridor_code_rb,
       b.gn_id,b.GN_DCMI TIS_MI,
       b.TIS_XCOORD TIS_X,b.TIS_YCOORD TIS_Y
from new_coll_corr_1_dont_use z,GN_DC_LOCATE b
where z.corridor_code_rb=b.DC_ID
union
select z.corridor_code_rb,
       e.gn_id,e.GN_DCMI TIS_MI,e.TIS_XCOORD TIS_X,
       e.TIS_YCOORD TIS_Y
from new_coll_corr_1_dont_use z,GN_DC_LOCATE e
where z.corridor_code_rb=e.DC_ID
order by 1,3
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
join (select corridor_code_rb,max(tis_mi) 
as tis_mi from new_coll_corr_2_dont_use
      group by corridor_code_rb) s
on t.tis_mi = s.tis_mi
ORDER BY 2,3
;
--*** Finds just the minimum or beginning mile for each new corridor
create or replace view min_mile_new_corr_dont_use as
select corridor_code_rb,tis_mi,tis_x,tis_y
from 
 (
   select corridor_code_rb,s.tis_mi,tis_x,tis_y,
      ROW_NUMBER()                        
      OVER (PARTITION BY corridor_code_rb 
            ORDER BY s.tis_mi ASC) AS rn 
      from new_coll_corr_3_dont_use s
 ) dt
WHERE rn = 1 
;
--*** Finds just the maximum or ending mile for each new corridor
create or replace view max_mile_new_corr_dont_use as
select corridor_code_rb,tis_mi,tis_x,tis_y
from 
 (
   select corridor_code_rb,s.tis_mi,tis_x,tis_y,
      ROW_NUMBER()                        
      OVER (PARTITION BY corridor_code_rb 
            ORDER BY s.tis_mi DESC) AS rn 
      from new_coll_corr_3_dont_use s
 ) dt
WHERE rn = 1 
;
---*** Creates the final dataset for new corridors to be included
create or replace view DATASET_NEW_CORRIDORS as
select distinct n.nrlg_dept_route as corridor_code,
s.corridor_code_rb,
n.nrlg_rte_name as road_pathweb,
s.tis_mi as begin_mi,
t.tis_mi as end_mi,
s.tis_x as start_lon,
s.tis_y as start_lat,
t.tis_x as end_lon,
t.tis_y as end_lat,
n.nrlg_plan_roadbed as rb,
n.nrlg_srf_type as p,
n.nrlg_fdist as district_no
from min_mile_new_corr_dont_use s 
join max_mile_new_corr_dont_use t on
s.corridor_code_rb = t.corridor_code_rb 
join TIS.TIS_NEW_ROADLOG n on 
t.corridor_code_rb = concat(n.nrlg_dept_route,n.nrlg_roadbed)
where n.nrlg_srf_type not like 'GRV'
and s.corridor_code_rb <> 'C000422N'
order by 1
;
---*** Creates blank columns to place into dataset for new corridors
create or replace view BLANKED_VAN_COLUMNS as
select 
cast (null as number)as van_no,
cast (null as number) as beg_gn,
cast (null as number) as end_gn,
cast (null as varchar(255)) as road_pathweb,
cast (null as varchar(255)) as corridor_code,
cast (null as varchar(255)) as secfile_name,
cast (null as varchar(255)) as county_name,
cast (null as varchar(255)) as from_descr,
cast (null as varchar(255)) as to_descr,
cast (null as number) as frfpost,
cast (null as number) as trfpost,
cast (null as varchar(255)) as dir,
cast (null as number) as svyleng2012,
cast (null as number) as lane,
cast (null as varchar(255)) as rb,
cast (null as number) as start_lat,
cast (null as number) as start_long,
cast (null as number) as end_lat,
cast (null as number) as end_long,
cast (null as varchar(255)) as p
from ops$u2970.sec_segments
;
---*** Creates increasing data record for misisng corridors
create or replace view final_corrs_all_rows_inc as
select t.corridor_code_rb,
s.road_pathweb,
s.van_no,s.beg_gn,s.end_gn,
t.corridor_code,
s.secfile_name,
s.county_name,
cast(t.district_no as number) as district_no,
t.road_pathweb as road_van,
s.from_descr,s.to_descr,
s.frfpost,s.trfpost,
t.begin_mi,t.end_mi,s.dir,
s.svyleng2012,
s.lane,s.rb,
t.start_lat,
t.start_lon,
t.end_lat,
t.end_lon,
t.p from BLANKED_VAN_COLUMNS s,
DATASET_NEW_CORRIDORS t
group by t.corridor_code_rb,
s.road_pathweb,
s.van_no,s.beg_gn,s.end_gn,
t.corridor_code,
s.secfile_name,
s.county_name,
t.district_no,
t.road_pathweb,s.from_descr,s.to_descr,
s.frfpost,s.trfpost,
t.begin_mi,t.end_mi,
s.dir,s.svyleng2012,
s.lane,s.rb,
t.start_lat,
t.start_lon,
t.end_lat,
t.end_lon,t.p
;
---*** Creates decreasing data record for missing corridors
create or replace view final_corrs_all_rows_dec as
select t.corridor_code_rb,
s.road_pathweb,
s.van_no,s.beg_gn,s.end_gn,
t.corridor_code,
s.secfile_name,
s.county_name,
cast(t.district_no as number) as district_no,
t.road_pathweb as road_van,
s.from_descr,s.to_descr,
s.frfpost,s.trfpost,
t.end_mi as begin_mi,
t.begin_mi as end_mi,
s.dir,s.svyleng2012,s.lane,s.rb,
t.end_lat as start_lat,
t.end_lon as start_lon,
t.start_lat as end_lat,
t.start_lon as end_lon,
t.p from BLANKED_VAN_COLUMNS s,
DATASET_NEW_CORRIDORS t
group by t.corridor_code_rb,
s.road_pathweb,
s.van_no,s.beg_gn,s.end_gn,
t.corridor_code,           
s.secfile_name,
s.county_name,
t.district_no,
t.road_pathweb,s.from_descr,s.to_descr,
s.frfpost,s.trfpost,
t.end_mi,t.begin_mi,
s.dir,s.svyleng2012,
s.lane,s.rb,
t.end_lat,
t.end_lon,
t.start_lat,
t.start_lon,t.p
;
---*** Combines increasing and decreasing records into one dataset
create or replace view NEW_SEGMENTS_DATA_VIEW as
select *
from final_corrs_all_rows_dec s
union all
select *
from final_corrs_all_rows_inc t
;
---*** Creates empty columns for final union with van data
create or replace view TIS_MILES_COORDS as
select
cast (null as number) as TIS_BEGMI,
cast (null as number) as TIS_ENDMI,
cast (null as number) as TIS_STARTX,
cast (null as number) as TIS_STARTY,
cast (null as number) as TIS_ENDX,
cast (null as number) as TIS_ENDY,
cast (null as varchar(11)) as TIS_BEGRP,
cast (null as varchar(11)) as TIS_ENDRP
from van_data_view
;
---*** Creates the final dataset for analysis and collection
create or replace view FINAL_DATASET_FOR_COLLECTION as
select t.*,s.*
from NEW_SEGMENTS_DATA_VIEW t,TIS_MILES_COORDS s
union all
select t.* from VAN_DATA_VIEW t
where t.corridor_code_rb <> 'C003102N'
order by 3,7,1,17 desc,19,15
