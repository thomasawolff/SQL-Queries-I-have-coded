create or replace view Surfacing_History_Report as
SELECT A.QC_CONTRACTNUMBER, 
RTRIM(B.QP_CONTROLNUMBER) QP_CONTROLNUMBER, 
B.QP_PROJECTNUMBER,B.QP_PROJECTNAME,
C.QMI_NAME, C.qmi_itemnumber, C.qmi_biditemname,  
F.QDP_NUMBERLIFTS, 'D' PHASE,
NULL MIN_TEMP, NULL  Max_temp,  
NULL  MIN_STARTTIME, NULL  MAX_STOPTIME, 
F.qdp_designasphalttype ASP_TYPE, 
qdp_designpercadditive1  AVG_ADD1,
qdp_designvfa  AVG_VFA,
f.qdp_designhydlimetype ADD1_TYPE, 
ROUND(f.qdp_designpercasphalt ,1) AVG_AC,  
f.qdp_designdensity  AVG_DEN,  
f.qdp_designpercvoids  AVG_VOID, 
f.qdp_designrice  AVG_RICE, 
'NA' ASP_SUPPLIER,   
'NA'  ADD1_SUPPLIER, 
qdp_designpercadditive2  AVG_ADD2,  
NVL(F.qdp_designadditive2type, 'NA') ADD2_TYPE,  
'NA' ADD2_SUPPLIER, G.QMM_STABILITYMINIMUM AVG_STAB, G.QMM_FLOWMINIMUM AVG_FLOW
FROM QAS.QA_CONTRACT A, QAS.QA_PROJECT B, QAS.QA_MATERIAL_ITEM C, QAS.QA_MATERIAL_VERSION D, 
QAS.QA_DAILY_PLANT_MIX_REPORT_DATA E,  QAS.QA_PLNT_MX_RPT_MATERIAL_INFO F, 
QAS.QA_MARSHALL_MATERIAL_INFO G,QAS.QA_MARSHALL_TEST_DATA K  
WHERE B.QP_MDT_FK          = A.QC_MDT_UID
   AND C.QMI_MDT_FK     = B.QP_MDT_UID
   AND D.QMV_MDT_FK     = C.QMI_MDT_UID
   AND E.QDP_MDT_FK     = D.QMV_MDT_UID
   AND F.QDP_MDT_FK     = E.QDP_MDT_UID
   AND K.QMD_MDT_FK(+)  = D.QMV_MDT_UID
   AND G.QMM_MDT_FK(+)  = K.QMD_MDT_UID
   group by A.QC_CONTRACTNUMBER, 
   B.QP_CONTROLNUMBER, B.QP_PROJECTNUMBER, B.QP_PROJECTNAME,
   C.QMI_NAME, C.qmi_itemnumber, C.qmi_biditemname,
   F.QDP_NUMBERLIFTS, 
   F.qdp_designasphalttype, f.qdp_designdensity, f.qdp_designrice,
   F.qdp_designpercadditive1, f.qdp_designpercvoids, f.qdp_designpercadditive1, 
   F.qdp_designpercadditive2,F.qdp_designadditive2type, qdp_designvfa, 
   f.qdp_designhydlimetype, f.qdp_designpercasphalt,
   G.QMM_STABILITYMINIMUM, G.QMM_FLOWMINIMUM
;
create or replace view PROJECT_NUMBERS_GROUPED as
select t.CONT_ID,t.FED_ST_PRJ_NBR,
cast(regexp_replace(nvl(substr(ROUTE_NBR,0,instr(ROUTE_NBR,',')-1),ROUTE_NBR),'[^0-9]','')as int) as sliced,
t.ROUTE_NBR,t.BEG_TERMINI,t.END_TERMINI
from SMGR.T_CONT t
group by t.CONT_ID,t.FED_ST_PRJ_NBR,t.ROUTE_NBR,
t.BEG_TERMINI,t.END_TERMINI
order by t.FED_ST_PRJ_NBR
;
create or replace view corridors_grouped_TIS as
select t.tcr_corridor_id,t.tcr_corridor_id || t.tcr_roadbed as Corridor_RB,
cast(regexp_replace(nvl(substr(t.tcr_corridor_id,0,
instr(t.tcr_corridor_id,',')-1),t.tcr_corridor_id),'[^0-9]','')as int) as sliced
from TIS.TIS_CORRIDOR_ROUTE t
where regexp_like(t.tcr_corridor_id,'[%C]')
group by  t.tcr_corridor_id,t.tcr_corridor_id || t.tcr_roadbed
order by t.tcr_corridor_id || t.tcr_roadbed
;
create or replace view COORDS_TO_FLOAT as
select distinct t.CONT_ID,s.Corridor_RB,s.tcr_corridor_id,t.FED_ST_PRJ_NBR,t.ROUTE_NBR,
case when t.BEG_TERMINI like '%RP%' or t.BEG_TERMINI like '%+%'
  then cast(regexp_replace(t.BEG_TERMINI,'[^0-9]','')/10.0 as VARCHAR(20))
    else t.BEG_TERMINI
      end as BEG_TERMINI,
case when t.END_TERMINI like '%RP%' or t.END_TERMINI like '%+%'
  then cast(regexp_replace(t.END_TERMINI,'[^0-9]','')/10.0 as VARCHAR(20))
    else t.END_TERMINI
      end as END_TERMINI,r.*
from corridors_grouped_TIS s inner join PROJECT_NUMBERS_GROUPED t
on t.sliced = s.sliced right join Surfacing_History_Report r
on trim(t.FED_ST_PRJ_NBR) = r.QP_PROJECTNUMBER
where t.ROUTE_NBR not in (select t.ROUTE_NBR 
from PROJECT_NUMBERS_GROUPED t where regexp_like(t.ROUTE_NBR,'[%L]'))
;
create or replace view BAD_COORDS_OUT as
select t.CONT_ID,t.Corridor_RB,t.FED_ST_PRJ_NBR,
t.ROUTE_NBR,t.beg_termini,t.end_termini,
t.QC_CONTRACTNUMBER,t.QP_CONTROLNUMBER,
t.QP_PROJECTNUMBER,t.QP_PROJECTNAME,
t.QMI_NAME,t.QMI_ITEMNUMBER,t.QMI_BIDITEMNAME,
t.QDP_NUMBERLIFTS,t.PHASE,
t.MIN_TEMP,t.MAX_TEMP,t.MIN_STARTTIME,
t.MAX_STOPTIME,t.ASP_TYPE,t.AVG_ADD1,
t.AVG_VFA,t.ADD1_TYPE,t.AVG_AC,
case when t.AVG_RICE > 145 and t.AVG_RICE < (148*1.2) 
  then ((t.AVG_RICE*16.0171)/1000) else t.AVG_RICE
end as AVG_RICE,
case when t.AVG_DEN > 145 and t.AVG_DEN < (148*1.2) 
  then ((t.AVG_DEN*16.0171)/1000) else t.AVG_DEN end as AVG_DEN,
t.AVG_VOID,t.ASP_SUPPLIER,t.AVG_ADD2,t.ADD2_TYPE,
t.ADD2_SUPPLIER,t.AVG_STAB,t.AVG_FLOW
from COORDS_TO_FLOAT t
;
create or replace view LONG_DENSITY as
select distinct t.CONT_ID,t.Corridor_RB,t.FED_ST_PRJ_NBR,
t.ROUTE_NBR,t.beg_termini,t.end_termini,
t.QC_CONTRACTNUMBER,
cast(t.QP_CONTROLNUMBER as varchar(4)) as QP_CONTROLNUMBER,
t.QP_PROJECTNUMBER,
t.QP_PROJECTNAME,
t.QMI_NAME,t.QMI_ITEMNUMBER,
t.QMI_BIDITEMNAME,
t.QDP_NUMBERLIFTS,t.PHASE,
t.MIN_TEMP,t.MAX_TEMP,t.MIN_STARTTIME,
t.MAX_STOPTIME,t.ASP_TYPE,t.AVG_ADD1,
t.AVG_VFA,t.ADD1_TYPE,t.AVG_AC,
case when t.AVG_DEN > 1000 then t.AVG_DEN/1000 else t.AVG_DEN end as AVG_DEN1,t.AVG_VOID,
case when t.AVG_RICE > 1000 then t.AVG_RICE/1000 else t.AVG_RICE end as AVG_RICE1,
t.ASP_SUPPLIER,t.AVG_ADD2,t.ADD2_TYPE,t.ADD2_SUPPLIER,t.AVG_STAB,t.AVG_FLOW
from bad_coords_out t
order by 2
;
create or replace view DATABASE_PROJECT_DESIGN as
select t.CONT_ID,t.Corridor_RB,
t.FED_ST_PRJ_NBR as PROJECT_NUMBER,t.ROUTE_NBR,
t.beg_termini as PROJECT_START,
t.end_termini as PROJECT_END,
t.QP_CONTROLNUMBER as CONTROL_NMBR,
t.QP_PROJECTNUMBER as PROJECT_NMBR,
t.QP_PROJECTNAME as PROJECT_NAME,
t.QMI_NAME,
t.QMI_ITEMNUMBER as ITEM_NUMBER,
t.QMI_BIDITEMNAME as BID_ITEM_NAME,
t.QDP_NUMBERLIFTS as NUMBER_LIFTS,
t.PHASE,t.ASP_TYPE as ASPHALT_TYPE,
t.AVG_ADD1 as DESIGN_PERC_ADDITIVE,
t.AVG_VFA as DESIGN_VFA,
t.ADD1_TYPE as ADDTIVE_1_TYPE,
t.AVG_AC as DESIGN_AVG_AC,
round(t.AVG_DEN1,3) as DESIGN_AVG_DEN
,t.AVG_VOID as DESIGN_HAMBURG_VOIDS,
t.ADD2_TYPE as ADDITIVE_2_TYPE,
round(t.AVG_RICE1,3) as DESIGN_RICE,
t.ASP_SUPPLIER as ASPHALT_SUPPLIER,
t.AVG_STAB,
t.AVG_FLOW 
from LONG_DENSITY t
;
create or replace view cont_ID_group as
select cont_id
from SMGR.T_CONT_MIX_DSN
group by cont_id
;
create or replace view as_built_Groups as
select t.mix_id from SMGR.T_CONT_MIX_DSN t
group by t.mix_id
;
create or replace view AS_BUILT_DATA as
select d.cont_id,t.MIX_ID,t.AIR_VOIDS_P,t.VMA_P,t.VFA_P,
t.BULK_SPC_GR_M,t.ASPH_CEM_T,t.OPT_AC_PCT_TOT_WT,t.ESALS_NBR
from SMGR.T_SUPERPAVE t
inner join as_built_Groups s 
on t.mix_id = s.mix_id
inner join SMGR.T_CONT_MIX_DSN d
on d.mix_id = s.mix_id
;
create or replace view ASPHALT_PROJECTS_MAP_DATA as
select distinct t.Corridor_RB,
t.PROJECT_NUMBER,
t.PROJECT_NAME as Description_,
s.MIX_ID,t.CONT_ID as Contract_ID,
PROJECT_START,PROJECT_END,
t.CONTROL_NMBR as Control_Number,
s.ESALS_NBR as ESALS,
s.OPT_AC_PCT_TOT_WT as As_Built_AC,
s.AIR_VOIDS_P as As_Built_Hamburg_Voids,
s.VMA_P as As_Built_VMA,
s.VFA_P as As_Built_VFA,
s.BULK_SPC_GR_M as As_Built_Specific_Gravity,
s.ASPH_CEM_T as As_Built_Mix_Type,
t.ASPHALT_TYPE as Design_Mix_Type,
t.DESIGN_AVG_AC as Design_AC,
t.ADDTIVE_1_TYPE as Design_Additive,
t.DESIGN_PERC_ADDITIVE,
t.DESIGN_HAMBURG_VOIDS,
t.DESIGN_VFA,
t.DESIGN_AVG_DEN as Design_Density,
t.DESIGN_RICE
from AS_BUILT_DATA s inner join cont_ID_group i
on s.cont_id = i.cont_id 
right join DATABASE_PROJECT_DESIGN t
on t.cont_id = i.cont_id
where t.PROJECT_END not like '%..%'
and t.PROJECT_START is not null
and trim(t.PROJECT_START) is not null
and t.PROJECT_START not in (select t.PROJECT_START from LONG_DENSITY t 
                            where regexp_like(t.PROJECT_START,'[^0-9 | ^/.]+'))
union all
select * from PROJECTS_EXCEL_FILE_021617 t
order by Corridor_RB,PROJECT_START,PROJECT_NUMBER
;
create or replace view NEWEST_ASPHALT_MAP_DATA as
select * from ASPHALT_PROJECTS_MAP_DATA
minus 
select * from ASPHALT_PROJECTS_021617
;
create or replace view NO_MILES_OR_BAD_INPUTS as
select distinct t.Corridor_RB,
t.PROJECT_NUMBER,
t.PROJECT_NAME as Description_,
s.MIX_ID,t.CONT_ID as Contract_ID,
PROJECT_START,PROJECT_END,
t.CONTROL_NMBR as Control_Number,
s.ESALS_NBR as ESALS,
s.OPT_AC_PCT_TOT_WT as As_Built_AC,
s.AIR_VOIDS_P as As_Built_Hamburg_Voids,
s.VMA_P as As_Built_VMA,
s.VFA_P as As_Built_VFA,
s.BULK_SPC_GR_M as As_Built_Specific_Gravity,
s.ASPH_CEM_T as As_Built_Mix_Type,
t.ASPHALT_TYPE as Design_Mix_Type,
t.DESIGN_AVG_AC as Design_AC,
t.ADDTIVE_1_TYPE as Design_Additive,
t.DESIGN_PERC_ADDITIVE,
t.DESIGN_HAMBURG_VOIDS,
t.DESIGN_VFA,
t.DESIGN_AVG_DEN as Design_Density,
t.DESIGN_RICE
from AS_BUILT_DATA s inner join cont_ID_group i
on s.cont_id = i.cont_id 
right join DATABASE_PROJECT_DESIGN t
on t.cont_id = i.cont_id
union all
select * from PROJECTS_EXCEL_FILE_021617 t
minus
select * from ASPHALT_PROJECTS_MAP_DATA



