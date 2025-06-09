create database Clique_Bait;
use Clique_Bait;

show tables;

-- 1.How many users are there?
select * from users;
select count(user_id) as No_of_users
from users;

-- 2.How many cookies does each user have on average?
select count(distinct cookie_id) / COUNT(distinct user_id) as avg_cookies_per_user
from users;

-- 3.What is the unique number of visits by all users per month?
-- 4.What is the number of events for each event type?
select * from event_identifier;
select * from events;

select event_name,events.event_type,count(*) as event_count
from events
inner join event_identifier on events.event_type=event_identifier.event_type
group by event_name,events.event_type;

-- 5.What is the percentage of visits which have a purchase event?
-- 6.What is the percentage of visits which view the checkout page but do not have a purchase event?
-- 7.What are the top 3 pages by number of views?
select * from events;
select * from page_hierarchy;

select page_name,count(events.page_id) as Total_Views
from events
inner join page_hierarchy on events.page_id=page_hierarchy.page_id
group by page_name
order by Total_Views desc
limit 3;

-- 8.What is the number of views and cart adds for each product category?


-- 9.What are the top 3 products by purchases?
with purchase_counts as (
select p.product_id,p.page_name as product_name,count(*) as purchase_count
from events e
join page_hierarchy p on e.page_id = p.page_id
where e.event_type = (select event_type from event_identifier where event_name = 'Purchase')
group by p.product_id, p.page_name
)
select product_id, product_name, purchase_count
from purchase_counts
order by purchase_count desc
limit 3;

select * from event_identifier where event_name = 'Purchase';

