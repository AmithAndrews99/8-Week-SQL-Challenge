create database Danny;
use danny;

show tables;
select * from members;
select * from menu;
select * from sales;

-- 1. What is the total amount each customer spent at the restaurant?
select customer_id, sum(price) as Total_Price from sales
inner join menu on sales.product_id = menu.product_id
group by customer_id;

-- or
-- when both the columns are same in both the tables
select customer_id, sum(price) as Total_Price from sales
inner join menu using(product_id)                        
group by customer_id;

-- 2. How many days has each customer visited the restaurant?
select distinct order_date,customer_id,
count(customer_id) as No_of_times from sales 
group by customer_id,order_date;

Select customer_id,count(customer_id) as No_of_Visits from
(select distinct order_date,customer_id,
count(customer_id) as No_of_times from sales 
group by customer_id,order_date) as t
group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?
select * from (
select *, row_number() over (partition by customer_id order by product_id)as drnk from sales inner join menu using (product_id)) as t
where drnk=1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select * from(

select product_name,count(product_name) as No_of_Purchases,
dense_rank() over(order by count(product_name)desc)as drnk from sales as t)
inner join menu using(product_id)

group by product_name where t.drnk=1;

-- 5. Which item was the most popular for each customer?

select * from(

select customer_id,product_name,count(*) as most_popular_item,
dense_rank() over(partition by customer_id order by count(product_name) desc)as drnk from sales s
inner join menu using(product_id) 

group by customer_id,product_name) as t

where drnk=1;

-- 6. Which item was purchased first by the customer after they became a member?

select* from(

select sales.customer_id,order_date,join_date,product_name,
row_number() over(partition by customer_id order by order_date asc) as rn from sales 
inner join members on sales.customer_id= members.customer_id and sales.order_date>members.join_date
inner join menu using(product_id))as t where t.rn=1;

-- 7. Which item was purchased just before the customer became a member?

select * from (

select sales.customer_id,order_date,join_date,product_name,
row_number() over(partition by sales.customer_id order by order_date desc)as rn from sales 
inner join members on sales.customer_id=members.customer_id and sales.order_date<members.customer_id
inner join menu using(product_id)) as t
where t.rn=1;

-- 8. What is the total items and amount spent for each member before they became a member?


select sales.customer_id,order_date,sales.product_id,menu.price,count(menu.product_name) as product_purchased,sum(price)*sales.product_id as Total_Price,
row_number() over(partition by sales.customer_id order by order_date desc) as rn from sales
inner join members on sales.customer_id=members.customer_id and sales.order_date<members.join_date
inner join menu on sales.product_id=menu.product_id
group by sales.customer_id,order_date,sales.product_id,menu.price;



select * from (
select s.customer_id, count(mu.product_name)as total_items, sum(price)as total_amount
from sales s inner join members m on s.customer_id=m.customer_id and s.order_date < m.join_date
inner join menu mu using(product_id) group by s.customer_id)as t ;


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select sales.customer_id,sum(case when menu.product_name= 'sushi' then price * 20
                                         else price * 10 end) as total_points
                                         from sales
inner join menu on sales.product_id=menu.product_id
group by sales.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?
-- DATEADD(date,interval date) or date_add(number,interval date)


select sales.customer_id,count(*) as No_of_Items,sum(case when order_date between join_date and adddate(join_date,interval 7 day) 
then menu.price * 20 when product_name = 'sushi' then menu.price * 20
												 else menu.price * 10 end) as Total_points
from sales
inner join members on sales.customer_id=members.customer_id
inner join menu using (product_id)
where month(sales.order_date)<= '01'
group by customer_id order by customer_id;


-- if the value of the item is more than the average then print high value item else print low value item

-- to find the average of points
select avg(points) as average from(
select *,case when menu.product_name= 'sushi' then price * 20
											  else price * 10 end as points
from sales 
inner join menu using(product_id)) as t;

--
select *,case when points<=144 then 'Low value item' else 'High value item' end as 'Status' from(
select *,case when menu.product_name= 'sushi' then price * 20
											  else price * 10 end as points
from sales 
inner join menu using(product_id)) as t;


-- using CTE

with CTE as (
select avg(points) as average_points from(
select *,case when menu.product_name= 'sushi' then price * 20
											  else price * 10 end as points
from sales 
inner join menu using(product_id)) as t) 

--

select *,case when points<=(select average_points from CTE) then 'Low value item' else 'High value item' end as 'Status' from(
select *,case when menu.product_name= 'sushi' then price * 20
											  else price * 10 end as points
from sales 
inner join menu using(product_id)) as t;

