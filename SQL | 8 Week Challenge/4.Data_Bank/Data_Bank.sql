-- 💾 Data Bank – SQL Case Study
-- -----------------------------
-- 🧱 Schema Setup
-- -----------------------------
CREATE DATABASE IF NOT EXISTS data_bank_db;
USE data_bank_db;

-- Regions
CREATE TABLE regions (
    region_id INT AUTO_INCREMENT PRIMARY KEY,
    region_name VARCHAR(50)
);

-- Customers
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100),
    email VARCHAR(100),
    join_date DATE
);

-- Customer Nodes
CREATE TABLE customer_nodes (
    node_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    region_id INT,
    node_name VARCHAR(50),
    start_date DATE,
    end_date DATE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (region_id) REFERENCES regions(region_id)
);

-- Transactions
CREATE TABLE transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    node_id INT,
    transaction_type ENUM('Deposit', 'Withdrawal', 'StorageFee'),
    amount DECIMAL(10,2),
    transaction_date DATE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (node_id) REFERENCES customer_nodes(node_id)
);

-- Storage Metrics
CREATE TABLE storage_metrics (
    metric_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    node_id INT,
    storage_used_mb DECIMAL(10,2),
    metric_date DATE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (node_id) REFERENCES customer_nodes(node_id)
);

-- -----------------------------
-- 📥 Insert Sample Data
-- -----------------------------
-- Regions
INSERT INTO regions (region_name) VALUES
('North America'),
('Europe'),
('Asia');

-- Customers
INSERT INTO customers (full_name, email, join_date) VALUES
('Aarav Sharma', 'aarav@example.com', '2023-01-10'),
('Emma Wilson', 'emma@example.com', '2023-02-15'),
('Li Wei', 'liwei@example.com', '2023-03-20'),
('Sophie Brown', 'sophie@example.com', '2023-04-25'),
('Rahul Gupta', 'rahul@example.com', '2023-05-30');

-- Customer Nodes
INSERT INTO customer_nodes (customer_id, region_id, node_name, start_date, end_date) VALUES
(1, 1, 'NA-Node1', '2023-01-10', '2023-06-30'),
(1, 2, 'EU-Node1', '2023-07-01', NULL),
(2, 1, 'NA-Node2', '2023-02-15', NULL),
(3, 3, 'AS-Node1', '2023-03-20', NULL),
(4, 2, 'EU-Node2', '2023-04-25', '2023-08-31'),
(4, 1, 'NA-Node3', '2023-09-01', NULL),
(5, 3, 'AS-Node2', '2023-05-30', NULL);

-- Transactions
INSERT INTO transactions (customer_id, node_id, transaction_type, amount, transaction_date) VALUES
(1, 1, 'Deposit', 5000.00, '2023-01-15'),
(1, 2, 'StorageFee', -200.00, '2023-07-05'),
(2, 3, 'Deposit', 3000.00, '2023-02-20'),
(2, 3, 'Withdrawal', -1000.00, '2023-03-10'),
(3, 4, 'Deposit', 4000.00, '2023-03-25'),
(4, 5, 'StorageFee', -150.00, '2023-05-01'),
(4, 6, 'Deposit', 6000.00, '2023-09-05'),
(5, 7, 'Deposit', 2000.00, '2023-06-01');

-- Storage Metrics
INSERT INTO storage_metrics (customer_id, node_id, storage_used_mb, metric_date) VALUES
(1, 1, 1000.00, '2023-01-31'),
(1, 2, 1500.00, '2023-07-31'),
(2, 3, 800.00, '2023-02-28'),
(3, 4, 1200.00, '2023-03-31'),
(4, 5, 2000.00, '2023-04-30'),
(4, 6, 2500.00, '2023-09-30'),
(5, 7, 600.00, '2023-06-30');

show tables;
select * from regions;
select * from customer_nodes;
select * from customers;
select * from transactions;
select * from storage_metrics;

#A. Customer Nodes Exploration
-- 1.How many unique nodes are there on the Data Bank system?

select distinct(node_name)
from customer_nodes;

-- 2.What is the number of nodes per region?

select regions.region_id, regions.region_name, count(node_id) as node_count
from customer_nodes cn
join regions on cn.region_id = regions.region_id
group by regions.region_id,regions.region_name;


-- 3.How many customers are allocated to each region?

select r.region_id,r.region_name, count(c.customer_id) as No_Cust_per_region
from customers c
join customer_nodes cn on c.customer_id=cn.customer_id
join regions r on cn.region_id = r.region_id
group by r.region_id,r.region_name;


-- 4.How many days on average are customers reallocated to a different node?

select * from customer_nodes;

with customer_node_dates AS (
								select
								customer_id,
								min(start_date) as first_date,
								max(end_date) AS last_date,
								count(*) AS node_count
								from customer_nodes
								group by customer_id
								having COUNT(*) > 1)
select
avg(DATEDIFF(last_date, first_date)) as avg_days_between_reallocations
from customer_node_dates;                               

-- 5.What is the median, 80th and 95th percentile for this same reallocation days metric for each region?


#B. Customer Transactions
-- 6.What is the unique count and total amount for each transaction type?

select * from transactions;
 select transaction_type,count(*) as total_transactions,count(distinct transaction_id) as unique_id, sum(amount) as total_amount
 from transactions
 group by transaction_type;
 
 
-- 7.What is the average total historical deposit counts and amounts for all customers?

select avg(deposit_count) as average_deposit_count,avg(deposit_amount) as average_deposit_amount
from(
select customer_id, COUNT(*) AS deposit_count, SUM(amount) AS deposit_amount
from transactions
where transaction_type = 'Deposit'
group by customer_id)
as customer_deposits;

-- 8.For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

select * from transactions;

select 
	year,
	month,
    count(distinct customer_id) as eligible_customers
from
(
select 
      customer_id,
      year(transaction_date) as year,
      month(transaction_date) as month,
      sum(transaction_type = 'Deposit') as deposit_count,
      sum(transaction_type IN ('Withdrawal', 'StorageFee')) as other_txn_count
    from transactions
    group by customer_id, year(transaction_date), month(transaction_date)
    ) as monthly_activity
    where deposit_count > 1 and other_txn_count >=1
    group by year,month
    order by year,month;
    
 
-- 9.What is the closing balance for each customer at the end of the month?

select * from transactions;

select customer_id, year(transaction_date) as year, month(transaction_date) as month,
sum(
case 
when transaction_type = 'Deposit' then amount
else -amount
end
) as closing_balance
from transactions
group by customer_id, year, month
order by customer_id,year,month;


-- 10.What is the percentage of customers who increase their closing balance by more than 5%?









