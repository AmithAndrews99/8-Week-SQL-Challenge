use foodie_fi;

select * from plans;
select * from subscriptions;

# A. Customer Journey

# Based off the 8 sample customers provided in the sample from the subscriptions table, 
# write a brief description about each customer’s onboarding journey. 

select s.customer_id, plan_name, s.start_date 
from plans p join subscriptions s using(plan_id)
where s.customer_id in ('1', '2','11','13','15','16','18','19')
group by s.customer_id, plan_name, s.start_date;

/* Customer 1: Started with a 7-day trial (2020-08-01) and Downgraded to Basic Monthly (2020-08-08).
Customer 2: Started with a 7-day trial (2020-09-20) and Upgraded to Pro Annual (2020-09-27).
Customer 11: Started with a 7-day trial (2020-11-19) and Churned (2020-11-26).
Customer 13: Started with a 7-day trial (2020-12-15) then Downgraded to Basic Monthly (2020-12-22) later Upgraded to Pro Monthly (2021-03-29).
Customer 15: Started with a 7-day trial (2020-03-17) then Upgraded to Pro Monthly (2020-03-24) later Churned (2020-04-29).
Customer 16: Started with a 7-day trial (2020-05-31) tehn Downgraded to Basic Monthly (2020-06-07) later Upgraded to Pro Annual (2020-10-21).
Customer 18: Started with a 7-day trial (2020-07-06) and Upgraded to Pro Monthly (2020-07-13).
Customer 19: Started with a 7-day trial (2020-06-22) then Upgraded to Pro Monthly (2020-06-29) later Upgraded to Pro Annual (2020-08-29).
*/



# B. Data Analysis Questions

# 1. How many customers has Foodie-Fi ever had? 
select count(distinct(customer_id)) as no_of_customers from subscriptions;



# 2. What is the monthly distribution of trial plan start_date values for our dataset 
# - use the start of the month as the group by value
select date_format(start_date,'%m-%Y') as trails, count(*) as trail_count
from subscriptions
where plan_id in ('0')
group by trails
order by trails;



# 3. What plan start_date values occur after the year 2020 for our dataset? 
# Show the breakdown by count of events for each plan_name
select plan_name, count(plan_name) as plan_count from subscriptions s join plans p using(plan_id)
where start_date > ('2020-12-31')
group by plan_name
order by plan_count;



# 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
select plan_name, count(distinct(customer_id)) as cust_count, 
	   round(count(distinct(customer_id)) * 100 / (select count(distinct(customer_id)) from subscriptions),2) as percentage
from subscriptions s join plans p using(plan_id)
where plan_id = 4
group by plan_name;



# 5. How many customers have churned straight after their initial free trial -
# what percentage is this rounded to the nearest whole number?
WITH trial_churn AS (
    SELECT customer_id
    FROM subscriptions
    WHERE plan_id = 0
)
SELECT 
    COUNT(s.customer_id) AS churned_customers,
    ROUND((COUNT(s.customer_id) * 100.0) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 0) AS churn_percentage
FROM subscriptions s
JOIN trial_churn t ON s.customer_id = t.customer_id
WHERE s.plan_id = 4;



# 6. What is the number and percentage of customer plans after their initial free trial?

select count(distinct customer_id) as cust_count, 
	   round((count(distinct customer_id) * 100.0) / 
          (select count(distinct customer_id) from subscriptions), 1) as percentage
from subscriptions
where plan_id not in ('0', '4');



# 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
select count(distinct customer_id) as cust_count, 
	   round(count(distinct customer_id) * 100.0 / (select count(distinct customer_id) from subscriptions),2) as percentage,
	   plan_name 
from plans p join subscriptions s using(plan_id)
where start_date <= '2020-12-31' and customer_id not in (
	select customer_id from subscriptions where start_date > '2020-12-31')
group by plan_name;



# 8. How many customers have upgraded to an annual plan in 2020?
select count(customer_id) as cust_count from subscriptions
where plan_id = 3 and start_date like '2020%';



# 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
SELECT ROUND(AVG(DATEDIFF(a.start_date, t.start_date)), 0) AS avg_days_to_annual
FROM subscriptions t
JOIN subscriptions a 
ON t.customer_id = a.customer_id
WHERE t.plan_id = 0 AND a.plan_id = 3;



# 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

# 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
select count(distinct s1.customer_id) as cust_count 
from subscriptions s1 join subscriptions s2 on s1.customer_id = s2.customer_id
where s1.plan_id = 1 and s2.plan_id = 2 and s1.start_date between '2020-01-01' and '2020-12-31';


