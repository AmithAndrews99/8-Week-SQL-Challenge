use pizza_runner;

# Cleaning customer_orders
UPDATE customer_orders
SET exclusions = NULL
WHERE exclusions = '' OR exclusions = 'null';

UPDATE customer_orders
SET extras = NULL
WHERE extras = '' OR extras = 'null';

# Cleaning runner_orders
UPDATE runner_orders
SET pickup_time = NULL
WHERE pickup_time = 'null';

UPDATE runner_orders
SET distance = CAST(REPLACE(distance, 'km', '') AS DECIMAL(5,2))
WHERE distance IS NOT NULL AND distance != 'null';

UPDATE runner_orders
SET duration = TRIM(REPLACE(duration, 'mins', ' minutes'))
WHERE duration LIKE '%mins';

UPDATE runner_orders
SET duration = TRIM(REPLACE(duration, 'minute', 'minutes'))
WHERE duration LIKE '%minute';

UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation = 'null';


# Clean the duration Column
UPDATE runner_orders
SET duration = REPLACE(duration, ' minutes', '');

UPDATE runner_orders
SET duration = REPLACE(duration, ' minute', '');

UPDATE runner_orders
SET duration = REPLACE(duration, 'mins', '');

UPDATE runner_orders
SET duration = REPLACE(duration, 'minutes', '');

UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation = '';

update runner_orders
set distance = null
WHERE distance = 'null';

update runner_orders
set duration = null
WHERE duration = 'null';

select * from customer_orders;
select * from pizza_names;
select * from pizza_recipes;
select * from pizza_toppings;
select * from runner_orders;


# A. Pizza Metrics

# 1. How many pizzas were ordered?
select count(order_id) as orders_count from customer_orders;


# 2. How many unique customer orders were made?
select count(distinct customer_id) as unique_customer from customer_orders;


# 3. How many successful orders were delivered by each runner?
select runner_id, count(order_id) as total_count from runner_orders
where cancellation is null
group by runner_id;


# 4. How many of each type of pizza was delivered?
select pizza_id, count(pizza_id) as pizza_count from customer_orders c join runner_orders r using(order_id)
where cancellation is null
group by pizza_id;

select pizza_name, count(c.pizza_id) as pizza_count from customer_orders c 
join runner_orders r using(order_id)
join pizza_names p on c.pizza_id = p.pizza_id
where cancellation is null
group by pizza_name;


# 5. How many Vegetarian and Meatlovers were ordered by each customer?
select customer_id, pizza_name, count(pizza_id) as pizza_count 
from customer_orders c join pizza_names p using(pizza_id)
group by customer_id, pizza_name;


# 6. What was the maximum number of pizzas delivered in a single order?
select max(pizza_count) from (
select count(pizza_id) as pizza_count from customer_orders c join runner_orders r using(order_id)
where cancellation is null
group by order_id) as subquery;

SELECT order_id, COUNT(pizza_id) AS max_pizzas  
FROM customer_orders c  
JOIN runner_orders r USING(order_id)  
WHERE r.cancellation IS NULL  
GROUP BY order_id  
ORDER BY max_pizzas DESC;


# 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
with info as (
select c1.customer_id, c1.pizza_id,
 case when c1.pizza_id != c2.pizza_id then 'Change' else 'No change' end as changes
from customer_orders c1 join customer_orders c2 using(order_id))
select customer_id, count(pizza_id) as pizza_count from info
where changes = 'Change'
group by customer_id;


select customer_id, 
	sum(case when exclusions is not null or extras is not null then 1 else 0 end) as changed_pizza,
    sum(case when exclusions is null and extras is null then 1 else 0 end) as unchanged_pizza
from customer_orders c join runner_orders r using(order_id)
where r.cancellation is null
group by customer_id;
 


# 8. How many pizzas were delivered that had both exclusions and extras?
select count(*) as special_pizza
from customer_orders c join runner_orders r using(order_id)
where r.cancellation is null
and exclusions is not null 
and extras is not null;


# 9. What was the total volume of pizzas ordered for each hour of the day?
select hour(order_time) as order_hour, count(*) as total_count
from customer_orders
group by order_hour
order by order_hour;


# 10. What was the volume of orders for each day of the week?



# B. Runner and Customer Experience

# 1. How many runners signed up for each 1 week period? 
SELECT 
    yearweek(registration_date) AS registration_week,
    COUNT(runner_id) AS runners_signed_up
FROM runners
GROUP BY registration_week
ORDER BY registration_week;


# 2. What was the average time in minutes it took for each runner 
# to arrive at the Pizza Runner HQ to pickup the order?

select runner_id, avg(cast(duration as unsigned)) as avg_time from runner_orders
group by runner_id;
select * from runners;



# 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
SELECT pizza_count, 
       AVG(prep_time) AS avg_prep_time
FROM (
    SELECT c.order_id, 
           COUNT(c.pizza_id) AS pizza_count, 
           CAST(duration AS UNSIGNED) AS prep_time
    FROM customer_orders c
    JOIN runner_orders r USING(order_id)
    WHERE r.cancellation IS NULL
    GROUP BY c.order_id, r.duration
) subquery
GROUP BY pizza_count
ORDER BY pizza_count;


# 4. What was the average distance travelled for each customer?
select customer_id, round(avg(distance),2) as avg_distance 
from customer_orders c join runner_orders r using(order_id)
group by customer_id;

SELECT runner_id, ROUND(AVG(duration), 2) AS avg_time
FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;


# 5. What was the difference between the longest and shortest delivery times for all orders?
select max(duration) - min(duration) as tim_diff
from runner_orders
where cancellation is null;



# 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
select order_id, runner_id, round((distance/duration),2) as avg_speed from runner_orders
where cancellation is null;


# 7. What is the successful delivery percentage for each runner?
select runner_id, round( 100 * sum(case when cancellation is null then 1 else 0 end)/count(*), 2) as percentage
from runner_orders
group by runner_id;



# C. Ingredient Optimisation

# 1. What are the standard ingredients for each pizza?


# 2. What was the most commonly added extra?
SELECT pt.topping_name, COUNT(*) AS extra_count  
FROM customer_orders c  
JOIN pizza_toppings pt  
ON FIND_IN_SET(pt.topping_id, c.extras)  
GROUP BY pt.topping_name  
ORDER BY extra_count DESC  
LIMIT 1;


# 3. What was the most commonly added exclusion?
SELECT pt.topping_name, COUNT(*) AS exclusion_count  
FROM customer_orders co  
JOIN pizza_toppings pt  
ON FIND_IN_SET(pt.topping_id, co.exclusions) > 0  
WHERE co.exclusions IS NOT NULL AND co.exclusions <> ''  
GROUP BY pt.topping_name  
ORDER BY exclusion_count DESC  
LIMIT 1;


