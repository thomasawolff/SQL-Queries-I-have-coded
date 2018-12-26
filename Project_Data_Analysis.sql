-- Aggregate the distress data into a joinable form with traffic data  
SELECT t.CORRIDOR_R, dt.BEGINMI, dt.ENDMI,  
ROUND(dt.ALLIGBMED,3) as 'ALLIGBMED (ft)',  
ROUND(dt.ALLIGBHIGH,3) as 'ALLIGBHIGH (ft)',  
ROUND(((dt.alligBmed/5280) / dt.ENDMI),5)*100 as ALLIG_B_MED_RATIO,  
ROUND(((dt.alligBhigh/5280) / dt.ENDMI),5)*100 as ALLIG_B_HIGH_RATIO, 
ROUND(dt.RIGHT_RUT_AVG,3) as RIGHT_RUT_AVG, 
ROUND(dt.LEFT_RUT_AVG,3) as LEFT_RUT_AVG into DISTRESS_TABLE 
  FROM [Project_Data_Export].[dbo].[NORTH_EXPORT_FULL_2017$] t 
  inner join (select s.CORRIDOR_R as CORRIDOR,  
MIN(s.FROM_) as BEGINMI, MAX(s.TO_) as ENDMI,  
AVG(s.RUT_L_AVG) as RIGHT_RUT_AVG, 
AVG(s.RUT_R_AVG) as LEFT_RUT_AVG, 
SUM(s.alligB_med) as ALLIGBMED, SUM(s.alligB_hig) as ALLIGBHIGH 
FROM [Project_Data_Export].[dbo].[NORTH_EXPORT_FULL_2017$] s 
where s.LANE = 1 
group by CORRIDOR_R 
) dt 
on t.CORRIDOR_R = dt.CORRIDOR 
where t.FROM_ = dt.BEGINMI 
and SUBSTRING(t.CORRIDOR_R,2,6) < 600 
group by t.CORRIDOR_R, dt.BEGINMI, dt.ENDMI, dt.ALLIGBMED, 
dt.ALLIGBHIGH,dt.RIGHT_RUT_AVG,dt.LEFT_RUT_AVG 
order by ALLIG_B_HIGH_RATIO desc 
 
 
-- Create primary key for the distress data table 
ALTER TABLE [Project_Data_Export].[dbo].[DISTRESS_TABLE] 
ALTER COLUMN CORRIDOR_R VARCHAR(20) NOT NULL 
ADD PRIMARY KEY(CORRIDOR_R) 
 
 
-- Aggregate the traffic data into a joinable form with distress data 
SELECT S.CORRIDORRB, dt.AADT_PER_MILE, dt.SUM_AADT,  
ROUND(dt.COMMERCIAL,3) as SUM_COMMERCIAL,  
ROUND((dt.LARGE_TRUCK,3) as SUM_LARGE_TRUCK,  
ROUND((dt.LARGE_TRUCK / ENDMI),5) as LARGE_TRUCK_RATIO, 
ROUND((dt.COMMERCIAL / ENDMI),5) as COMMERCIAL_RATIO INTO TRAFFIC_TABLE 
  FROM [Project_Data_Export].[dbo].[TRAFFIC_DATA_2017$] s 
  inner join (select t.[CORRIDORRB] AS ROUTE_, SUM(T.TYC_AADT) AS SUM_AADT, 
ROUND(SUM(T.TYC_AADT)/MAX(t.ENDMI),3) AS AADT_PER_MILE,  
MIN(t.BEGMI) as BEGMI, MAX(t.ENDMI) AS ENDMI,  
SUM(t.TYC_COMMERCIAL) AS COMMERCIAL,  
SUM(TYC_LARGE_TRUCK) AS LARGE_TRUCK 
from [Project_Data_Export].[dbo].[TRAFFIC_DATA_2017$] t 
group by t.[CORRIDORRB] 
) dt 
on s.[CORRIDORRB] = dt.ROUTE_ 
where SUBSTRING(dt.ROUTE_,2,6) < 600  
and dt.COMMERCIAL is not null and dt.LARGE_TRUCK is not null 
group by S.CORRIDORRB, AADT_PER_MILE, SUM_AADT, dt.BEGMI, dt.ENDMI,  
dt.AADT_PER_MILE, dt.SUM_AADT, dt.COMMERCIAL, dt.LARGE_TRUCK 
order by LARGE_TRUCK_RATIO desc 
 
 
-- Create primary key for the traffic data table 
ALTER TABLE [Project_Data_Export].[dbo].[TRAFFIC_TABLE] 
ALTER COLUMN CORRIDORRB VARCHAR(20) NOT NULL 
ADD PRIMARY KEY(CORRIDORRB) 
 
 
-- Join the traffic and distress data using primary keys created above 
SELECT T.*,S.SUM_AADT, S.AADT_PER_MILE, S.SUM_COMMERCIAL,S.SUM_LARGE_TRUCK, 
S.COMMERCIAL_RATIO, S.LARGE_TRUCK_RATIO INTO TRAFFIC_DISTRESS_JOIN 
FROM TRAFFIC_TABLE S INNER JOIN DISTRESS_TABLE T 
ON S.CORRIDORRB = T.CORRIDOR_R 
where T.CORRIDOR_R <> 'C000015N' and T.ENDMI > 4 and T.ALLIG_B_HIGH_RATIO > 0 
 
 
-- Eliminate rows with outliers in Alligator B High data using IQR 
select t.* into TRAFFIC_DISTRESS_OUTLIER_FILTERED 
from TRAFFIC_DISTRESS_JOIN t cross join  
     (select min(ALLIG_B_HIGH_RATIO) as q1, max(ALLIG_B_HIGH_RATIO) as q3, 
 max(ALLIG_B_HIGH_RATIO) - min(ALLIG_B_HIGH_RATIO) as iqr 
      from (select ALLIG_B_HIGH_RATIO, 
                   row_number() over (order by ALLIG_B_HIGH_RATIO) as seqnum, 
                   count(*) over (partition by null) as total 
from TRAFFIC_DISTRESS_JOIN s 
where seqnum = cast(total*0.25 as int) or seqnum = cast(total*0.75 as int) 
     ) qs 
 where ALLIG_B_HIGH_RATIO < q3 + 1.5*iqr 
