create or replace view New_Leslie_Data as
select distinct s.smpl_dt, m.matl_cd, s.geog_area_t, s.smpl_id, r.smpl_tst_nbr,
                decode(r.tst_fld_sn,'23',r.tst_strg_fld_val) Assay,
                decode(r.tst_fld_sn,'26',r.tst_strg_fld_val) Effectiveness_pns_score,
                decode(r.tst_fld_sn,'29',r.tst_strg_fld_val) PNS_Blank,
                decode(r.tst_fld_sn,'32',r.tst_strg_fld_val) PNS_NaCl,
                decode(r.tst_fld_sn,'35',r.tst_strg_fld_val) Settable_Solids,
                decode(r.tst_fld_sn,'38',r.tst_strg_fld_val) Settable_Solids_Temp,
                decode(r.tst_fld_sn,'41',r.tst_strg_fld_val) Percent_Pass_10m,
                decode(r.tst_fld_sn,'44',r.tst_strg_fld_val) pH,
                decode(r.tst_fld_sn,'47',r.tst_strg_fld_val) As_,
                decode(r.tst_fld_sn,'50',r.tst_strg_fld_val) Ba,
                decode(r.tst_fld_sn,'53',r.tst_strg_fld_val) Cd,
                decode(r.tst_fld_sn,'56',r.tst_strg_fld_val) Cr,
                decode(r.tst_fld_sn,'59',r.tst_strg_fld_val) Cu,
                decode(r.tst_fld_sn,'62',r.tst_strg_fld_val) Pb,
                decode(r.tst_fld_sn,'65',r.tst_strg_fld_val) Hg,
                decode(r.tst_fld_sn,'68',r.tst_strg_fld_val) Se,
                decode(r.tst_fld_sn,'71',r.tst_strg_fld_val) Zn,
                decode(r.tst_fld_sn,'74',r.tst_strg_fld_val) CN,
                decode(r.tst_fld_sn,'77',r.tst_strg_fld_val) P,
                decode(r.tst_fld_sn,'80',r.tst_strg_fld_val) S,
                decode(r.tst_fld_sn,'83',r.tst_strg_fld_val) Sulfate,
                decode(r.tst_fld_sn,'86',r.tst_strg_fld_val) Phosphate,
                decode(r.tst_fld_sn,'92',r.tst_strg_fld_val) K,
                decode(r.tst_fld_sn,'95',r.tst_strg_fld_val) Ca,
                decode(r.tst_fld_sn,'98',r.tst_strg_fld_val) Mg,
                decode(r.tst_fld_sn,'101',r.tst_strg_fld_val) Nitrite,
                decode(r.tst_fld_sn,'104',r.tst_strg_fld_val) Nitrate,
                decode(r.tst_fld_sn,'107',r.tst_strg_fld_val) Chloride--,
               -- r.tst_strg_fld_val Result_Value
from t_smpl s,
     t_smpl_tst st,
     t_tst_rslt_dtl r,
     t_matl m
where r.tst_meth = '000MCIG000'
and m.matl_cd = s.matl_cd
and s.smpl_id = r.smpl_id
and st.smpl_id = s.smpl_id
and r.tst_meth = st.tst_meth
and r.smpl_tst_nbr = st.smpl_tst_nbr
and r.tst_fld_sn in ('23','26','29','32','35','38','41','44','47','50','53','56','59','62','65','68',
                     '71','74','77','80','83','86','89','92','95','98','101','104','107')
;

select t.smpl_id,t.smpl_tst_nbr,t.matl_cd,t.geog_area_t,
case when max(t.assay) like ' ' then null else max(t.assay) end as assay,
case when max(t.effectiveness_pns_score) like ' ' 
then null else max(t.effectivenesspns_score) end as effectiveness_pns_score,
case when max(t.pns_blank) like ' ' then null else max(t.pns_blank) end as pns_blank,
case when max(t.pns_nacl) like ' ' then null else max(t.pns_nacl) end as pns_nacl,
case when max(t.settable_solids) like ' ' then null else max(t.settable_solids) end as settable_solids,
case when max(t.percent_pass_10m) like '' then null else max(t.percent_pass_10m) end as percent_pass_10m,
case when max(t.ph) like ' ' then null else max(t.ph) end as ph,
case when max(t.as_) like ' ' then null else max(t.as_) end as as_,
case when max(t.ba) like ' ' then null else max(t.ba) end as ba,
case when max(t.cd) like ' ' then null else max(t.cd) end as cd,
case when max(t.cr) like ' ' then null else max(t.cr) end as cr,
case when max(t.cu) like ' ' then null else max(t.cu) end as cu,
case when max(t.pb) like ' ' then null else max(t.pb) end as pb,
case when max(t.hg) like ' ' then null else max(t.hg) end as hg,
case when max(t.se) like ' ' then null else max(t.se) end as se,
case when max(t.zn) like ' ' then null else max(t.zn) end as zn,
case when max(t.cn) like ' ' then null else max(t.cn) end as cn,
case when max(t.p) like ' ' then null else max(t.p) end as p,
case when max(t.s) like ' ' then null else max(t.s) end as s,
case when max(t.sulfate) like ' ' then null else max(t.sulfate) end as sulfate,
case when max(t.phosphate) like ' ' then null else max(t.phosphate) end as phosphate,
case when max(t.k) like ' ' then null else max(t.k) end as k,
case when max(t.ca) like ' ' then null else max(t.ca) end as ca,
case when min(t.mg) like ' ' then null else min(t.mg) end as mg,
case when max(t.nitrite) like ' ' then null else max(t.nitrite) end as nitrite,
case when max(t.nitrate) like ' ' then null else max(t.nitrate) end as nitrate,
case when max(t.chloride) like ' ' then null else max(t.nitrate) end as chloride
from New_Leslie_Data t 
group by t.smpl_id,t.smpl_tst_nbr,t.matl_cd,t.geog_area_t
order by 1
