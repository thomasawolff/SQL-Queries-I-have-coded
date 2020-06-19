/****** Script for SelectTopNRows command from SSMS  ******/
use [Covid Course Project]
go


SELECT [fips]
      ,[county]
      ,[state]
      ,max([cases]) as maxCases
      ,max([deaths]) as maxDeaths into maxCovidCountyData
  FROM [Covid Course Project].[dbo].[CovidCountyCases] where fips is not NULL
  group by county,state,fips
  order by 3,1,4

  create unique clustered index maxCovidCountyDataUnique on maxCovidCountyData(state,county)
  create unique index maxCovidCountyDataU on maxCovidCountyData(fips)


  SELECT [fips]
      ,[county]
      ,[state] into StateCountyData
 
  FROM [Covid Course Project].[dbo].[CovidCountyCases] where fips is not NULL
  group by county,state,fips
  order by 2


  create unique clustered index StateCountyDataUnique on StateCountyData(state,county)
  create unique index StateCountyDataU on StateCountyData(fips)


  select m.Fips
	,m.[state]
	,m.county
	,m.maxCases as Positives
	,round(((m.maxCases/a.tot_pop)*100000),2) as [Positives Per 100,000]
	,m.maxDeaths as Deaths
	,round(((m.maxDeaths/a.tot_pop)*100000),2) as [Deaths Per 100,000]
	,h.HousingUnits
	,c.[Median income (2 earners)]
	,i.[Living with Income Assistance] as [Living with Income Assistance (people)]
	,l.[2018 Estimate: Population 16 years and over In labor force] as [2018 Estimate: Population 16 years and over In labor force (%)]
	,s.*,d.*,a.*
	from maxCovidCountyData m 
	inner join AllCountyDemoData a on m.county = a.[CTYNAME] and m.state = a.[STNAME]
	inner join HousingCleanedData h on h.County = a.[CTYNAME] and ltrim(h.state) = a.[STNAME] 
	left join IncomeAssistance i on i.fips = m.fips
	left join EstimateDisabled d on d.fips = m.fips
	left join MedianIncomes c on c.fips = m.fips
	left join [Labor Force] l on l.fips = m.fips
	left join [LaborForceIndustry] s on s.fips = m.fips
	where i.[Living with Income Assistance] is not NULL
	order by 1

create unique clustered index AgesDemoDataNewColUniq on AgesDemoDataNewCol(Fips)

SELECT TOP (1000) s.[Fips]
      ,[State]
      ,[County]
	  ,[TOT_POP] as Total_Population
      ,[TOT_MALE] as Total_Male
      ,[TOT_FEMALE] as Total_Female
	  ,a.*
      ,[Positives]
      ,[Positives_Per_100_000] as [Positives_Per_100,000]
      ,[Deaths]
      ,[Deaths_Per_100_000] as [Deaths_Per_100,000]
	  ,[HousingUnits]
      ,[Median_income_2_earners]
      ,round((cast([Living_with_Income_Assistance_people] as float)/cast([TOT_POP] as float))*100,2) as [People_Living_with_Income_Assistance (Percent)]
      ,[_2018_Estimate_Population_16_years_and_over_In_labor_force] as [Estimate_Population_16_years_and_over_In_labor_force (Percent)]
      ,[Agriculture_forestry_fishing_and_hunting_and_mining] as [Agriculture_forestry_fishing_and_hunting_and_mining (Percent)]
      ,[Construction] as [Construction (Percent)]
      ,[Manufacturing] as [Manufacturing (Percent)]
      ,[Wholesale_trade] as [Wholesale_trade (Percent)]
      ,[Retail_trade] as [Retail_trade (Percent)]
      ,[Transportation_and_warehousing_and_utilities] as [Transportation_and_warehousing_and_utilities (Percent)]
      ,[Information] as [Information (Percent)]
      ,[Finance_and_insurance_and_real_estate_and_rental_and_leasing] as [Finance_and_insurance_and_real_estate_and_rental (Percent)]
      ,[Professional_scientific_and_management_and_administrative_and] as [Professional_scientific_and_management_and_administrative (Percent)]
      ,[Educational_services_and_health_care_and_social_assistance] as [Educational_services_and_health_care_and_social_assist (Percent)]
      ,[Arts_entertainment_and_recreation_and_accommodation_and_food] as [Arts_entertainment_and_recreation_and_accommodation (Percent)]
      ,[Other_services_except_public_administration] as [Other_services_except_public_admin (Percent)]
      ,[Public_administration] as [Public_administration (Percent)]
      ,[Private_wage_and_salary_workers] as [Private_wage_and_salary_workers (Percent)]
      ,[Government_workers] as [Government_workers (Percent)]
      ,[Self_employed_in_own_not_incorporated_business_workers] as [Self_employed (Percent)]
      ,[Unpaid_family_workers] as [Unpaid_family_workers (Percent)]
      ,[With_health_insurance_coverage] as [With_health_insurance_coverage (Percent)]
      ,[No_health_insurance_coverage] as [No_health_insurance_coverage (Percent)]
      ,round((cast([Estimate_Total_Male_Under_5_years_With_a_disability] as float)/cast(TOT_MALE as float))*100,2) as [Estimate_Total_Male_Under_5_years_With_a_disability (Percent)]
      ,round((cast([Estimate_Total_Male_5_to_17_years_With_a_disability] as float)/cast(TOT_MALE as float))*100,2) as [Estimate_Total_Male_5_to_17_years_With_a_disability (Percent)]
      ,round((cast([Estimate_Total_Male_18_to_34_years_With_a_disability] as float)/cast([TOT_MALE] as float))*100,2) as [Estimate_Total_Male_18_to_34_years_With_a_disability (Percent)]
      ,round((cast([Estimate_Total_Male_35_to_64_years_With_a_disability] as float)/cast([TOT_MALE] as float))*100,2) as [Estimate_Total_Male_35_to_64_years_With_a_disability (Percent)]
      ,round((cast([Estimate_Total_Male_65_to_74_years_With_a_disability] as float)/cast([TOT_MALE] as float))*100,2) as [Estimate_Total_Male_65_to_74_years_With_a_disability (Percent)]
      ,round((cast([Estimate_Total_Male_75_years_and_over_With_a_disability] as float)/cast([TOT_MALE] as float))*100,2) as [Estimate_Total_Male_75_years_and_over_With_a_disability (Percent)]
      ,round((cast([Estimate_Total_Female_Under_5_years_With_a_disability] as float)/cast([TOT_FEMALE] as float))*100,2) as [Estimate_Total_Female_Under_5_years_With_a_disability (Percent)]
      ,round((cast([Estimate_Total_Female_5_to_17_years_With_a_disability] as float)/cast([TOT_FEMALE] as float))*100,2) as [Estimate_Total_Female_5_to_17_years_With_a_disability (Percent)]
      ,round((cast([Estimate_Total_Female_18_to_34_years_With_a_disability] as float)/cast([TOT_FEMALE] as float))*100,2) as [Estimate_Total_Female_18_to_34_years_With_a_disability (Percent)]
      ,round((cast([Estimate_Total_Female_35_to_64_years_With_a_disability] as float)/cast([TOT_FEMALE] as float))*100,2) as [Estimate_Total_Female_35_to_64_years_With_a_disability (Percent)]
      ,round((cast([Estimate_Total_Female_65_to_74_years_With_a_disability] as float)/cast([TOT_FEMALE] as float))*100,2) as [Estimate_Total_Female_65_to_74_years_With_a_disability (Percent)]
      ,round((cast([Estimate_Total_Female_75_years_and_over_With_a_disability] as float)/cast([TOT_FEMALE] as float))*100,2) as [Estimate_Total_Female_75_years_and_over_With_a_disability (Percent)]
      ,round((cast([WA_MALE] as float)/cast(TOT_MALE as float))*100,2) as [White_Males (Percent)]
      ,round((cast([WA_FEMALE] as float)/cast([TOT_FEMALE] as float))*100,2) as [White_Females (Percent)]
      ,round((cast([BA_MALE] as float)/cast(TOT_MALE as float))*100,2) as [African_American_Males (Percent)]
      ,round((cast([BA_FEMALE] as float)/cast([TOT_FEMALE] as float))*100,2) as [African_American_Females (Percent)]
      ,round((cast([IA_MALE] as float)/cast(TOT_MALE as float))*100,2) as [American_Indian_Male (Percent)]
      ,round((cast([IA_FEMALE] as float)/cast([TOT_FEMALE] as float))*100,2) as [American_Indian_Female (Percent)]
      ,round((cast([AA_MALE] as float)/cast(TOT_MALE as float))*100,2) as [Asian_Male (Percent)]
      ,round((cast([AA_FEMALE] as float)/cast([TOT_FEMALE] as float))*100,2) as [Asian_Female (Percent)]
      ,round((cast([NA_MALE] as float)/cast(TOT_MALE as float))*100,2) as [Native_Hawaiian_or_Pacific_Islands_Male (Percent)]
      ,round((cast([NA_FEMALE] as float)/cast([TOT_FEMALE] as float))*100,2) as [Native_Hawaiian_or_Pacific_Islands_Female (Percent)]
      ,round((cast([TOM_MALE] as float)/cast(TOT_MALE as float))*100,2) as [Two_Or_More_Races_Male (Percent)]
      ,round((cast([TOM_FEMALE] as float)/cast([TOT_FEMALE] as float))*100,2) as [Two_Or_More_Races_Female (Percent)]
  FROM [Covid_Course_Project].[dbo].[CountyCovidDataAll2] s inner join AgesDemoDataNewCol a on s.Fips = a.Fips