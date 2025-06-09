CREATE SCHEMA fresh_segments;
use fresh_segments;
DROP TABLE IF EXISTS fresh_segments.json_data;
CREATE TABLE fresh_segments.json_data (raw_data JSON);


-- update the null values
UPDATE fresh_segments.interest_map
SET interest_summary = NULL
WHERE interest_summary = '';


  select * from interest_map_full;
  select * from interest_metrics;
  select * from json_data;
  
  show tables;
  
-- Data Exploration and Cleansing
-- 1.Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month



-- 2.What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) 
--   with the null values appearing first?

select month_year, COUNT(*) AS record_count
from fresh_segments.interest_metrics
group by month_year
order by ISNULL(month_year),month_year ASC;


-- 3.What do you think we should do with these null values in the fresh_segments.interest_metrics


-- 4.How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table?
--   What about the other way around?

select count(distinct interest_id) as interest_metrics_but_not_in_map
from interest_metrics
where interest_id is not null and interest_id not in(select id from interest_map_full);

select count(distinct id) as interest_map_but_not_in_metrics
from interest_map_full
where id is not null and id not in(select interest_id from interest_metrics);


-- 5.Summarise the id values in the fresh_segments.interest_map by its total record count in this table

select interest_name, count(interest_name) as Count
from interest_map_full
group by interest_name
order by Count desc;

-- 6.What sort of table join should we perform for our analysis and why? 
--   Check your logic by checking the rows where interest_id = 21246 in your joined output and 
--   include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.

select 
    interest_metrics.*,                  
    interest_map_full.interest_name,
    interest_map_full.interest_summary,
    interest_map_full.created_at,
    interest_map_full.last_modified
from interest_metrics 
left join interest_map_full on interest_id = id
where interest_id = 18923;
-- we used left join because this will return metrics data even if the interest details are missing (NULL in those columns).


-- 7.Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? 
--   Do you think these values are valid and why?

select imf.id,imf.interest_name,im.month_year,imf.created_at
from interest_metrics im
join interest_map_full imf on im.interest_id = imf.id
where STR_TO_DATE(im.month_year, '%m-%Y') < STR_TO_DATE(imf.created_at, '%Y-%m-%d')
limit 10;


-- Interest Analysis
-- 8.Which interests have been present in all month_year dates in our dataset?
select * from interest_metrics;
select * from interest_map_full;

select count(distinct month_year) as total_months
from interest_metrics;

select interest_id, count(distinct month_year) as months_present
from interest_metrics
group by interest_id;

WITH all_months AS (
    SELECT COUNT(DISTINCT month_year) AS total_months
    FROM interest_metrics
),
interest_months AS (
    SELECT interest_id, COUNT(DISTINCT month_year) AS months_present
    FROM interest_metrics
    GROUP BY interest_id
)
SELECT im.interest_id, imf.interest_name
FROM interest_months im
JOIN all_months am ON im.months_present = am.total_months
JOIN interest_map_full imf ON im.interest_id = imf.id;


-- 9.Using this same total_months measure - calculate the cumulative percentage of all records 
--   starting at 14 months - which total_months value passes the 90% cumulative percentage value?

with interest_months as (
						select interest_id, count(distinct month_year) as months_present
						from interest_metrics
						group by interest_id),
                         
	counts_per_months_present as (
						select months_present, count(*) as interest_count
						from interest_months
						group by months_present),
                        
	filtered_counts as (
						select * 
						from counts_per_months_present 
						where months_present >= 14),

	cumulative as (
						select months_present,interest_count,sum(interest_count) over (order by months_present) as cumulative_count,
						sum(interest_count) over () as total_count
						from filtered_counts
),

	final_result AS (
						select months_present,interest_count,cumulative_count,total_count,
						round(100.0 * cumulative_count / total_count, 2) as cumulative_percentage
						from cumulative
)

select *
from final_result
where cumulative_percentage >= 90
order by months_present
limit 1;


-- 10.If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - 
--    how many total data points would we be removing?

WITH interest_months AS (
    SELECT interest_id, COUNT(DISTINCT month_year) AS months_present
    FROM interest_metrics
    GROUP BY interest_id
),

interest_to_remove AS (
    SELECT interest_id
    FROM interest_months
    WHERE months_present < 17  -- Use the threshold from Q9
)

SELECT COUNT(*) AS rows_to_remove
FROM interest_metrics
WHERE interest_id IN (SELECT interest_id FROM interest_to_remove);




-- 11.Does this decision make sense to remove these data points from a business perspective? 
--    Use an example where there are all 14 months present to a removed interest example for your arguments - 
--    think about what it means to have less months present from a segment perspective.


-- 12.After removing these interests - how many unique interests are there for each month?

