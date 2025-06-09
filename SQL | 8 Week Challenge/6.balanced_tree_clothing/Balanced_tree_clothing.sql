create database balanced_tree_clothing;
use balanced_tree_clothing;

show tables;
select * from product_details;
select * from product_hierarchy;
select * from product_prices;
select * from product_sales;


-- 1.What was the total quantity sold for all products?
select sum(qty) as total_quantity_sold from product_sales;


-- 2.What is the total generated revenue for all products before discounts?
select sum(qty*(price-discount)) as Total_Revenue from product_sales;


-- 3.What was the total discount amount for all products?
select sum(qty*discount) as Total_sales from product_sales;

-- 4.How many unique transactions were there?
select distinct(txn_id) from product_sales;

-- 5.What is the average unique products purchased in each transaction?
select * from product_sales;

select avg(unique_products) as avg_unique_products_per_txn
from (
select prod_id,count(distinct prod_id) as unique_products
from product_sales
group by prod_id
) as sub_query;


-- 6.What are the 25th, 50th and 75th percentile values for the revenue per transaction?


-- 7.What is the average discount value per transaction?
select txn_id,avg(discount) as AVG_Dis
from product_sales
group by txn_id;

-- 8.What is the percentage split of all transactions for members vs non-members?
-- 9.What is the average revenue for member transactions and non-member transactions?

-- 10.What are the top 3 products by total revenue before discount?
select product_name, sum(qty*product_sales.price) as total_revenue
from product_details
inner join product_sales on product_details.product_id=product_sales.prod_id
group by product_name
order by total_revenue desc
limit 3;


-- 11.What is the total quantity, revenue and discount for each segment?
select * from product_details;
select * from product_sales;

select product_details.segment_name,sum(qty) as Total_Quantity,sum(qty*product_sales.price) as Total_Revenue,sum(discount) as Total_Discount
from product_sales
inner join product_details on product_sales.prod_id=product_details.product_id
group by product_details.segment_name;

-- 12.What is the top selling product for each segment?
select * from product_sales;

with ranked_prdt as(
select segment_name,product_name,sum(qty) as Total_Quantity, rank() over (partition by segment_name order by sum(qty)desc) as rnk 
from product_details
inner join product_sales on product_details.product_id=product_sales.prod_id
group by segment_name,product_name
)

select segment_name, product_name, total_quantity,rnk
from ranked_prdt
where rnk=1;


-- 13. What is the total quantity, revenue and discount for each category?
select category_name,sum(qty) as Total_Quantity, sum(qty*product_sales.price) as Total_Revenue, sum(discount) as Total_Discount
from product_details
inner join product_sales on product_details.product_id=product_sales.prod_id
group by category_name;

-- 14. What is the top selling product for each category?

with CTE as(
select category_name,product_name,sum(qty) as Total_Quantity, rank() over(partition by category_name order by sum(qty) desc) as rnk
from product_sales
inner join product_details on product_sales.prod_id=product_details.product_id
group by category_name,product_name
)

select category_name,product_name,total_quantity
from CTE
where rnk=1;


-- 15. What is the percentage split of revenue by product for each segment?
-- 16. What is the percentage split of revenue by segment for each category?
-- 17. What is the percentage split of total revenue by category?
-- 18. What is the total transaction “penetration” for each product? 
-- (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
-- 19. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
