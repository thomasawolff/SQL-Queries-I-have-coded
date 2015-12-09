--***Creates a VIEW of all TIS GN's with their Corridor ID, Accum Mile and XY coords
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
--***Creates a VIEW of all begin and end GN's on ops$u2087.sec_segments
   --from the view GN_DC_LOCATE and adds in the records where GN=999999999999
create or replace view PVMGT_SEGS_GNs_DCMI as
select p.corridor_code_rb,
       b.gn_id,b.GN_DCMI TIS_MI,
       b.TIS_XCOORD TIS_X,b.TIS_YCOORD TIS_Y
from ops$u2970.sec_segments_thomas p, GN_DC_LOCATE b
where p.corridor_code_rb=b.DC_ID and p.beg_gn=b.gn_id
UNION
select p.corridor_code_rb,
       e.gn_id,e.GN_DCMI TIS_MI,e.TIS_XCOORD TIS_X,e.TIS_YCOORD TIS_Y
from ops$u2970.sec_segments_thomas p,GN_DC_LOCATE e
where p.corridor_code_rb=e.DC_ID and p.end_gn=e.gn_id
UNION
select p.corridor_code_rb,999999999999 GN_ID, NULL TIS_MI,NULL TIS_X,NULL TIS_Y
from ops$u2970.sec_segments_thomas p
where p.beg_gn=999999999999 or p.end_gn=999999999999
order by 1,3
;
--***Creates a VIEW of all said GN's with their Reference Points
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
--***Queries ops$u2087.sec_segments along with the TIS locations in the view PVMGT_GNs_DCMI_RP
create or replace view VAN_DATA_VIEW_2016 as
select p.*,
       lb.TIS_MI TIS_BEGMI,le.TIS_MI TIS_ENDMI,
       lb.TIS_X TIS_STARTX,lb.TIS_Y TIS_STARTY,
       le.TIS_X TIS_ENDX,le.TIS_Y TIS_ENDY,
       lb.REF_POINT TIS_BEGRP,le.REF_POINT TIS_ENDRP
from ops$u2970.sec_segments_thomas p,PVMGT_GNs_DCMI_RP lb,PVMGT_GNs_DCMI_RP le
where p.corridor_code_rb=lb.corridor_code_rb and p.beg_gn=lb.gn_id
      and p.corridor_code_rb=le.corridor_code_rb and p.end_gn=le.gn_id
      --and p.van_no = '12174'
      --and secfile_name = 'North'
      order by p.corridor_code_rb,p.dir DESC,p.lane, p.begin_mi
;
--***Queries the roadlog for corridor records on system and paved that are not in van dataset
create or replace view new_coll_corr_1_dont_use as
select distinct concat(t.nrlg_dept_route,t.nrlg_roadbed) as corridor_code_rb
from TIS.TIS_NEW_ROADLOG t
where t.nrlg_srf_type like 'PMS'
(and t.nrlg_sys_desc not like 'OFF'
and t.nrlg_sys_desc not like 'OUT'
and t.nrlg_sys_desc not like 'CLO')
(or t.nrlg_srf_type like 'PCC'
and t.nrlg_sys_desc not like 'OFF'
and t.nrlg_sys_desc not like 'OUT'
and t.nrlg_sys_desc not like 'CLO')
(or t.nrlg_srf_type like 'BST'
and t.nrlg_sys_desc not like 'OFF'
and t.nrlg_sys_desc not like 'OUT'
and t.nrlg_sys_desc not like 'CLO')
(or t.nrlg_srf_type like 'RMS'
and t.nrlg_sys_desc not like 'OFF'
and t.nrlg_sys_desc not like 'OUT'
and t.nrlg_sys_desc not like 'CLO')
minus
select s.corridor_code_rb
from ops$u2970.sec_segments_thomas s
order by 1
;
--***Combines the view data from above with mile and coordinate data from TIS
create or replace view new_coll_corr_2_dont_use as
select z.corridor_code_rb,
       b.gn_id,b.GN_DCMI TIS_MI,
       b.TIS_XCOORD TIS_X,b.TIS_YCOORD TIS_Y
from new_coll_corr_1_dont_use z,GN_DC_LOCATE b
where z.corridor_code_rb=b.DC_ID
UNION
select z.corridor_code_rb,
       e.gn_id,e.GN_DCMI TIS_MI,
       e.TIS_XCOORD TIS_X,e.TIS_YCOORD TIS_Y
from new_coll_corr_1_dont_use z,GN_DC_LOCATE e
where z.corridor_code_rb=e.DC_ID
order by 1,3
;
--***Breaks down corridor mile data from above down to just min and max miles
create or replace view new_coll_corr_3_dont_use as
select t.gn_id,t.corridor_code_rb,t.TIS_MI,t.TIS_X,t.TIS_Y
from new_coll_corr_2_dont_use t
where t.tis_mi = (select min(tis_mi) from new_coll_corr_2_dont_use s)
union
select t.gn_id,t.corridor_code_rb,t.TIS_MI,t.TIS_X,t.TIS_Y
from new_coll_corr_2_dont_use t
join (select corridor_code_rb,max(tis_mi) as tis_mi from new_coll_corr_2_dont_use
      group by corridor_code_rb) s
on t.tis_mi = s.tis_mi
ORDER BY 2,3
;
--***Finds just the minimum or beginning mile for each new corridor
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
--***Finds just the maximum or ending mile for each new corridor
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
---***Brings together min mile, max mile,corridor rb and coordinates for mapping
create or replace view final_dataset_new_corr_2016 as
select s.corridor_code_rb,s.tis_mi as begMi,t.tis_mi as endMi,
s.tis_x as startX, s.tis_y as startY,t.tis_x as endX, t.tis_y as endY
from min_mile_new_corr_dont_use s join max_mile_new_corr_dont_use t on
s.corridor_code_rb = t.corridor_code_rb
order by 1
;
select distinct concat(t.nrlg_dept_route,t.nrlg_roadbed) as corridor_code_rb,
nrlg_plan_route,
t.nrlg_rte_name,
v.begMi,
v.endMi,
t.nrlg_county,
t.nrlg_srf_type
from TIS.TIS_NEW_ROADLOG t join FINAL_DATASET_NEW_CORR_2016 v on
concat(t.nrlg_dept_route,t.nrlg_roadbed) = v.corridor_code_rb
where t.nrlg_srf_type not like 'GRV'
order by 1
