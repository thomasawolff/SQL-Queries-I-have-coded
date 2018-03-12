
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
create or replace view VAN_DATA_VIEW as
select distinct p.corridor_code_rb,p.road_pathweb,p.van_no,
case when p.beg_gn <> ys.gn_id and p.corridor_code_rb = ys.dc_id and p.begin_mi >= ys.gn_dcmi
  then ys.gn_id
    else p.beg_gn
      end as beg_gn,
p.end_gn,p.corridor_code,p.secfile_name,
p.county_name,p.district_no,p.road_van,p.from_descr,
p.to_descr,p.frfpost,p.trfpost,p.begin_mi,p.end_mi,
p.dir,p.svyleng2012,p.lane,p.rb,
p.start_lat,p.start_lon,p.end_lat,p.end_lon,p.p,
lb.TIS_MI TIS_BEGMI,le.TIS_MI TIS_ENDMI,
lb.TIS_X TIS_STARTX,lb.TIS_Y TIS_STARTY,
le.TIS_X TIS_ENDX,le.TIS_Y TIS_ENDY,
lb.REF_POINT TIS_BEGRP,le.REF_POINT TIS_ENDRP
from PVMT_EXT_MDT.SEC_SEGMENTS_NEW_COL_FALLS_2 p left join PVMGT_GNs_DCMI_RP_TABLE lb 
on p.corridor_code_rb=lb.corridor_code_rb and p.beg_gn=lb.gn_id
left join PVMGT_GNs_DCMI_RP_TABLE le 
on p.corridor_code_rb=le.corridor_code_rb and p.end_gn=le.gn_id
left join GN_DC_LOCATE_JOIN_TABLE ys on ys.gn_id <> p.beg_gn 
and ys.dc_id = p.corridor_code_rb and ys.gn_dcmi = p.begin_mi
--order by 7,6
--order by p.corridor_code_rb,p.dir DESC,p.lane, p.begin_mi
;
----------------*************************************************-----------------------------

--*** Combines the view data from above with mile and coordinate data from TIS
create or replace view new_coll_corr_2_dont_use as
select z.corridor_code_rb,
b.gn_id,b.GN_DCMI TIS_MI,
b.TIS_XCOORD TIS_X,
b.TIS_YCOORD TIS_Y
from NEW_CORRS_FINDER_TABLE z inner join GN_DC_LOCATE_JOIN_TABLE b
on z.corridor_code_rb=b.DC_ID
union
select z.corridor_code_rb,
e.gn_id,e.GN_DCMI TIS_MI,
e.TIS_XCOORD TIS_X,
e.TIS_YCOORD TIS_Y
from NEW_CORRS_FINDER_TABLE z inner join GN_DC_LOCATE_JOIN_TABLE e
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
--create or replace view FINAL_DATASET_12174 as
select s.*
from VAN_DATA_VIEW s
where s.VAN_NO = 12174
and s.CORRIDOR_CODE not like 'C901002'
and s.ROAD_VAN not like '%Ant Flat Road%'
minus
select s.*
from VAN_DATA_VIEW s inner join forest_highways_hwy_table t
on s.CORRIDOR_CODE like 'C0'||t.Corridor
where s.VAN_NO = 12174 and t.Corridor > 600
union
select b.*,null,null,null,null,null,null,null,null 
from sec_segments b
where b.corridor_code_rb = (select t.corridor_code_rb from SEC_SEGMENTS t
                            where t.van_no = 12174
                            group by corridor_code_rb
                            minus
                            select p.corridor_code_rb from PVMT_EXT_MDT.SEC_SEGMENTS_NEW_COL_FALLS_2 p
                            where p.van_no = 12174
                            group by corridor_code_rb)
order by 3,7,1,17 desc,19,15

----------------*************************************************-----------------------------
;
---*** Filters out the forest roads from the final collection dataset for van 12175
/*create or replace view FINAL_DATASET_12175 as
select s.*
from VAN_DATA_VIEW s
where s.VAN_NO = 12175
and s.CORRIDOR_CODE not like 'C901002'
and s.ROAD_VAN not like '%Ant Flat Road%'
minus
select s.*
from VAN_DATA_VIEW s inner join forest_highways_hwy_table t
on s.CORRIDOR_CODE like 'C0'||t.Corridor
where s.VAN_NO = 12175 and t.Corridor > 600
union
select b.*,null,null,null,null,null,null,null,null 
from sec_segments b
where b.corridor_code_rb = (select t.corridor_code_rb from SEC_SEGMENTS t
                            where t.van_no = 12175
                            group by corridor_code_rb
                            minus
                            select p.corridor_code_rb from PVMT_EXT_MDT.SEC_SEGMENTS_NEW_COL_FALLS_2 p
                            where p.van_no = 12175
                            group by corridor_code_rb)
order by 5 desc,3,7,1,17 desc,19,15*/
;
----------------*************************************************-----------------------------


