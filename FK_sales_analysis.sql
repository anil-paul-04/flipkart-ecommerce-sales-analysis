use FKsalesDB


-- total recerds 
select count(*) from FlipkartSales

-- check null values 
select * 
from FlipkartSales 
where SKU IS null 

-- check duplicates order id 
select 
[Order ID], 
count(*) 
from FlipkartSales
group by [Order ID]
having count(*) > 1

SELECT *
FROM FlipkartSales
WHERE [Order ID] = 'OD337724440015722100';

SELECT [Event Sub Type], COUNT(*) AS Total_Records
FROM FlipkartSales
GROUP BY [Event Sub Type]
ORDER BY Total_Records DESC;

SELECT
    ISNULL([Event Sub Type], 'NULL') AS Event_Type,
    COUNT(*) AS Total_Records
FROM FlipkartSales
GROUP BY [Event Sub Type]
ORDER BY Total_Records DESC;

SELECT
    CASE
        WHEN [Event Sub Type] IS NULL THEN 'NULL'
        WHEN LTRIM(RTRIM([Event Sub Type])) = '' THEN 'Blank'
        ELSE [Event Sub Type]
    END AS Event_Type,
    COUNT(*) AS Total_Records
FROM FlipkartSales
GROUP BY
    CASE
        WHEN [Event Sub Type] IS NULL THEN 'NULL'
        WHEN LTRIM(RTRIM([Event Sub Type])) = '' THEN 'Blank'
        ELSE [Event Sub Type]
    END;

    -- counting the no of rows 
    SELECT COUNT(*) AS Total_Rows
FROM FlipkartSales;


-- count no of rows in the column
SELECT COUNT([Event Sub Type])
FROM FlipkartSales;

-- counting no of null values 
select count([Event Sub Type]) 
from FlipkartSales 
where [Event Sub Type] is null

-- checking the dates 
select 
    CAST(min([Order Date]) as date)  as first_date,
    CAST( max([Order Date])AS date) as last_date
from FlipkartSales

-- change DATE type from DATETIME 
ALTER TABLE FlipkartSales
ALTER COLUMN [Order Date] DATE;

-- removing "" from SKU column
update FlipkartSales
set SKU = TRIM(REPLACE(SKU,'SKU:',''))

-- removing "" from FSN column
update FlipkartSales
set FSN = TRIM(REPLACE(FSN,'""',''))

-- check for top 10 , is there any "" or no 
select TOP 10 FSN,SKU,[Product Title] from FlipkartSales

-- checking how many rows are there after removing 
SELECT 
    count(FSN) as old,
    count(TRIM(REPLACE(FSN, '"', '')))  AS Cleaned_FSN
from FlipkartSales

-- checking the dataset in breaf 
EXEC sp_help 'FlipkartSales';

-- checking for null values 
select 
    count(*) as null_values
from FlipkartSales 
WHERE [Order Date] is null

select
[Order ID],
count(*) as duplicates
from FlipkartSales
group by [Order ID]
having count(*) > 1 

-- 1) BUSINUESS OVERVIEW / KPI's
drop view vw_KPI_Summary
create view vw_KPI_Summary AS 
select 
    count(distinct [Order ID])as total_orders,
    sum([Item Quantity]) as total_quantities,
    sum([Price after discount]) as total_revenue,
    ABS(sum([Total Discount])) as total_discount,
    ROUND(AVG([Price after discount]),2)as avg_selling_price 
from FlipkartSales;
select * from vw_KPI_Summary
-- INSIGHTS:
-- Processed 2,966 unique orders in June 2026.
-- Sold 4,184 units and generated ₹2,126,783 in revenue.
-- Average selling price was ₹562.34 per line item.

-- Sales Analysis 

-- 2) Daily Sales Trend 
-- The Head of Sales has noticed that sales fluctuate throughout the month. Before planning future campaigns, 
-- management wants to understand the daily business performance during June 2026.
create view vw_daily_sales_trend AS 
select 
    [Order Date] as order_date,
    sum([Item Quantity])as total_quantity,
    sum([Price after discount]) as total_revenue
from flipkartSales
group by [Order Date] 
-- order by [Order Date]

-- INSIGHTS:
-- Daily sales remained consistent throughout June 2026.
-- June 21 achieved the highest orders and revenue, while June 26 recorded the lowest sales performance.

-- Q3) Weekly Sales Performance
-- The Sales Manager wants to know how sales are performing week by week instead of day by day. This will help evaluate weekly campaigns,
-- inventory planning, and operational performance.
create view vw_weekly_Sales AS 
select
    [Week],
    count(distinct [Order ID])as total_orders,
    sum([Price after discount]) as total_revenue
from FlipkartSales
group by [Week]
-- order by [Week]

-- INSIGHTS:
-- Week 4 recorded the highest orders and revenue, while Week 3 had the lowest performance.
-- Sales showed a noticeable improvement during the final week of June 2026.

-- Q4) Weekday vs Weekend Sales Analysis
-- The Marketing Manager wants to understand customer buying behaviour on weekdays versus weekends.
-- This information will help the company decide when to run promotions, flash sales, and advertising campaigns.
create view vw_weedayVSweekend AS 
select 
    [Day Type],
    count(distinct [Order ID]) as total_orders,
    sum([Item Quantity]) as total_quantitu,
    sum([Price after discount])as total_revenue 
from FlipkartSales
group by [Day Type]

-- INSIGHTS:
-- Weekdays generated significantly higher orders, quantity sold, and revenue than weekends.
-- The business should continue focusing promotional activities on weekdays while exploring strategies to improve weekend sales.

-- Q5) Low Performing Products Identified Using Business Thresholds
-- "We have over 400 SKUs in our catalogue. Marketing budget is limited, so we cannot promote every product.
-- Then identify the Bottom 10 Products by Revenue.
create view vw_Bottom10 AS 
select Top 10  
    SKU,
    [Product Title],
    count(distinct [Order ID])as total_orders ,
    sum([Item Quantity]) as total_quantity,
    sum([Price after discount]) as total_revenue
from FlipkartSales
group by SKU,[Product Title]
having  sum([Price after discount]) < 500 
AND count(distinct [Order ID]) <= 2 
AND sum([Item Quantity]) <=2
Order by total_revenue asc

-- INSIGHTS:
-- Products meeting the defined business thresholds generated low revenue,
-- received very few orders, and sold limited quantities.
-- These products should be reviewed for pricing, inventory availability,
-- and marketing performance before any business decision is taken.

-- Q6) Identify High-Value (Premium) Products
-- "Some products don't sell frequently, but whenever they do, they generate significant revenue. 
--       We don't want to judge products only by order volume."
--  Identify products that generate high revenue with relatively few orders so we can consider
--       premium pricing strategies and targeted marketing."

create view vw_high_value AS 
select TOP 10
    SKU,
    [Product Title],
    count( distinct [Order ID]) as total_orders,
    sum([Price after discount]) as total_revenue,
    sum([Price after discount]) / count( distinct [Order ID]) as avg_order_value
from FlipkartSales
group by SKU,[Product Title]
having count( distinct [Order ID])<=2 
AND sum([Price after discount])>= 2000
Order by avg_order_value desc 

-- INSIGHTS:
-- Premium products were identified based on high revenue generated from only one or two customer orders.
-- These products have the highest average revenue per order, making them suitable for premium pricing
-- and targeted marketing rather than mass promotional campaigns.

-- Q7) "Some products are receiving many customer orders but are generating relatively low revenue.
--     I want to identify these products because they may be heavily discounted or priced too low.
--  Please identify products that have high order volume but low average revenue per order."
create view vw_Top10 AS 
select top 10
    SKU,
    [Product Title],
    sum([Item Quantity]) as total_quantity,
    sum([Price after discount]) as total_revenue,
    sum([Total Discount])*-1 as total_discount, -- can use ABS() or SUM([Total Discount]) * -1 to remove discounts in - vlaues 
    count(distinct [Order ID])as total_orders,
    ROUND(sum([Price after discount]) / count(distinct [Order ID]),2) as avg_order_value
from FlipkartSales
group by SKU,[Product Title]
having count(distinct [Order ID]) >=10 
AND sum([Price after discount]) / count(distinct [Order ID])<=1000
order by total_orders desc

-- INSIGHTS:
-- These products generated high order volumes but relatively low average revenue per order.
-- They contribute significantly to sales volume but generate lower revenue per transaction.
-- Management should review pricing, discount strategies, and product bundling opportunities
-- to improve revenue while maintaining customer demand.


-- Q8) "We've been offering discounts on many products to increase sales. However,
-- I'm concerned that some products are receiving high discounts without generating sufficient revenue.
-- Please identify such products so we can review our pricing strategy."
create view vw_offer_discount AS 
select TOP 10
  SKU,
  count(distinct [Order ID])as total_orders,
  ABS(sum([Total Discount]))as total_discount,
  sum([Price after discount])as total_revenue,
  round(ABS(sum([Total Discount])) / count(distinct [Order ID]),2) as avg_discount_amt
from FlipkartSales
group by SKU
HAVING
COUNT(DISTINCT [Order ID]) >= 3
AND ROUND(
    ABS(SUM([Total Discount])) * 1.0 /
    COUNT(DISTINCT [Order ID]), 2
) >= 100
AND SUM([Price after discount]) <= 5000

-- Insight:
-- Products with at least 3 orders, an average discount above ₹100 per order,
-- and total revenue below ₹5,000 were identified. These products may require
-- a review of their pricing and discount strategy, as higher discounts are not
-- translating into strong revenue.

-- Q9) State-wise Sales Performance Analysis
-- The Regional Sales Manager wants to know:
-- Which states generate the highest revenue?
-- Which states contribute the most orders?
-- Which states need more marketing attention?
create view vw_Statewise_sales AS 
select top 10 
    [Customer's Delivery State] as cust_states,
    count(distinct [Order ID])as total_orders,
    sum([Price after discount]) as total_revenue,
    sum([Item Quantity])as total_quantity,
    ROUND(sum([Price after discount]) / count(distinct [Order ID]),2) as avg_order_value
from FlipkartSales
group by [Customer's Delivery State]
order by total_orders desc
    
-- Insight:
-- Tamil Nadu and Karnataka generated the highest number of orders,
-- indicating strong customer demand. States with higher Average Order Value
-- present opportunities for premium product sales, while states with lower
-- revenue or order volume may require targeted marketing efforts.

-- Q10) Top Products Within Each State
-- Which products perform the best in each state?
create view vw_TopProdcut_instate AS 
with top_states as (
select 
    [Customer's Delivery State]as states,
    SKU,
    count(distinct [Order ID])as total_orders,
    sum([Price after discount]) as total_revenue,
    DENSE_RANK() over(partition by [Customer's Delivery State] order by sum([Price after discount]) desc) as ranks
from FlipkartSales
where [Customer's Delivery State] is not null  AND [Customer's Delivery State] <> '-'
group by [Customer's Delivery State],SKU
)
select 
     *
from top_states
where ranks<=3
order by states, ranks 

-- Insight:
-- Product performance varies across states, with some SKUs consistently
-- ranking among the top revenue generators in multiple regions. These
-- insights can help optimize regional inventory allocation and support
-- targeted marketing strategies.

-- 11Q) Which fulfilment method (FBF or Non-FBF) performs better?
create view vw_FBF_non_FBF AS 
select 
    [Fulfilment Type],
    count(distinct [Order ID]) as total_orders,
    sum([Item Quantity])as total_qty,
    sum([Price after discount])as total_revenue,
    ROUND(sum([Price after discount])/ count(distinct [Order ID]),2)as avg_order_value
from  FlipkartSales
group by [Fulfilment Type]
order by total_revenue
-- Insight:
-- NON_FBF is the dominant fulfilment method, contributing the highest
-- number of orders, quantity sold, and total revenue. This indicates
-- that most customer orders are processed through the NON_FBF channel.
--
-- Comparing the Average Order Value (AOV) helps determine whether
-- FBF customers place higher-value orders despite having fewer orders.
-- These insights can support decisions related to fulfilment strategy,
-- warehouse planning, and operational efficiency.

-- Q12)How does revenue accumulate throughout the month?
create view vw_running_revenue AS 
with daily_sales as(
select
    [Order Date],
    sum([Price after discount])as daily_revenue
from FlipkartSales
where [Order Date] between '2026-06-01' AND '2026-06-30'
group by  [Order Date]
)
select 
    [Order Date],
    daily_revenue,
    sum(daily_revenue) over(order by [Order Date])as running_sales
from daily_sales
order by [Order Date] 
-- Insight:
-- The running revenue analysis shows how sales accumulated throughout
-- June 2026. Revenue increased consistently each day, reaching a total
-- cumulative revenue of ₹2,126,783 by the end of the month.
--
-- This analysis helps management monitor sales progress against monthly
-- targets and identify high-performing days that contributed most to
-- overall business revenue.

-- Q13) How did today's revenue compare with yesterday's revenue?
create view vw_comp_Yestoday AS 
with daily_sales as(
select 
    [Order Date]as order_date,
    sum([Price after discount])as daily_revenue
from flipkartSales
group by [Order Date]
)
select 
    order_date,
    daily_revenue,
    LAG(daily_revenue,1) over(order by order_date)as previous_revenue,
    daily_revenue - LAG(daily_revenue,1,0) over(order by order_date)as revenue_diff
from daily_sales;

-- Business Insight:
-- This analysis compares each day's revenue with the previous day's revenue
-- to identify daily sales fluctuations. Positive values indicate revenue growth,
-- while negative values indicate a decline compared to the previous day.
--
-- Such analysis helps manage ment monitor daily business performance,
-- identify unusual sales patterns, and take timely actions to improve revenue.

-- Q14 – Revenue Contribution Analysis (%)
-- Which SKUs contribute the highest percentage of the total revenue?
create view vw_revenue_contribution AS 
with sku_revenue as(
    select 
        SKU,
        count(DISTINCT [Order ID]) as total_orders,
        sum([Price after discount]) as total_revenue
    from FlipkartSales
    group by SKU
)
select top 10 
    SKU,
    total_orders,
    total_revenue,
    ROUND(total_revenue * 100.0/ sum(total_revenue) over(),2) AS revenue_percentage 
from sku_revenue
order by total_revenue desc; 
-- Business Insight:
-- The top revenue-generating SKUs contribute a significant portion of total sales.
-- '210x110-squaredesign' is the highest contributor (6.22%), followed by
-- 'TG_thmac_des-205x100' (4.22%). These SKUs should be prioritized for
-- inventory management and promotional strategies.


-- Q15) Management wants to see the overall business performance for the month of June in one query, including:
-- Total Orders,Total Quantity Sold, Total Revenue, Average Order Value (AOV), Average Selling Price (ASP), Total Discount, Revenue per Unit
create view vw_AOV AS 
select 
    count(distinct [Order ID])as total_order,
    sum([Item Quantity]) as total_qty,
    sum([Price after discount])as total_revenue,
    ROUND(sum([Price after discount]) * 1.0 /count(distinct [Order ID]),2) as avg_order_value,
    ROUND(sum([Price after discount]) *1.0 / sum([Item Quantity]),2) as avg_selling_price,
    sum([Total Discount])*-1 as total_discount
from FlipkartSales
-- Insight:
-- During June 2026, the business processed 2,966 orders and sold 4,184 units,
-- generating a total revenue of ₹2,126,783 with an Average Order Value (AOV)
-- of ₹717.05 and an Average Selling Price (ASP) of ₹508.31. A total discount
-- of ₹129,617 was offered during the month. This executive summary provides
-- a quick overview of the company's overall sales performance and serves as
-- the starting point for deeper product, customer, and regional analysis.

-- Q16) Sales vs Cancelled vs Returned Orders Analysis
-- Management wants to understand the overall order status distribution.
create view vw_Event_type_perfomance AS 
SELECT
    [Event Sub Type],
    COUNT(DISTINCT [Order ID]) AS total_orders,
    ROUND(
        COUNT(DISTINCT [Order ID]) * 100.0 /
        SUM(COUNT(DISTINCT [Order ID])) OVER(),
        2
    ) AS order_percentage
FROM FlipkartSales
GROUP BY [Event Sub Type]
ORDER BY total_orders DESC;

-- Business Insight:
-- Sales account for the majority of all orders, while returns and
-- cancellations represent a smaller share. Monitoring return and
-- cancellation rates helps identify operational issues and improve
-- customer satisfaction.

-- Q17) State-wise Return Rate Analysis
-- Management wants to identify states with the highest return rates.
create view vw_State_wise_return AS 
SELECT
    [Customer's Delivery State] AS state,

    COUNT(DISTINCT CASE
        WHEN [Event Sub Type] = 'Sale'
        THEN [Order ID]
    END) AS total_sales,

    COUNT(DISTINCT CASE
        WHEN [Event Sub Type] = 'Return'
        THEN [Order ID]
    END) AS total_returns,

    CAST(
    ROUND(
        COUNT(DISTINCT CASE
            WHEN [Event Sub Type] = 'Return'
            THEN [Order ID]
        END) * 100.0 /

        NULLIF(
            COUNT(DISTINCT CASE
                WHEN [Event Sub Type] = 'Sale'
                THEN [Order ID]
            END),
            0
        ),
        2
    ) AS decimal(10,2)) AS return_percentage

FROM FlipkartSales

GROUP BY [Customer's Delivery State]

HAVING COUNT(DISTINCT CASE
            WHEN [Event Sub Type] = 'Sale'
            THEN [Order ID]
       END) > 20

ORDER BY return_percentage DESC;

-- Business Insight:
-- Bihar (27.91%), Madhya Pradesh (24.00%), and Odisha (23.86%)
-- have the highest return percentages, indicating potential issues
-- related to product quality, customer expectations, or delivery.
-- These states should be prioritized for return analysis and
-- corrective actions to reduce return rates and improve profitability.

-- Q18) SKU-wise Return Analysis
-- Management wants to identify products with the highest return rates so they can:
-- Improve product quality Check misleading product descriptions,Improve packaging,Reduce revenue loss
create view vw_SKU_wise_return AS 
select 
    SKU,
    count(distinct 
    case
        when [Event Sub Type] = 'Sale' then [Order ID]
        END) as total_sales,
    count(distinct 
    case
        when [Event Sub Type] = 'Return' then [Order ID]
        END) as total_return,

    CAST(
    ROUND(
     count(distinct 
    case
        when [Event Sub Type] = 'Return' then [Order ID]
        END) * 100.0 /
    count(distinct 
    case
        when [Event Sub Type] = 'Sale' then [Order ID]
        END),
        2
        )AS decimal(10,2)) AS return_rate
from FlipkartSales
group by SKU
having
count(distinct 
case
    when [Event Sub Type] = 'Return' then [Order ID]
    END) >=10

order by return_rate desc
-- Business Insight:
-- Several SKUs have return rates above 25%, indicating potential issues
-- related to product quality, customer expectations, or product listings.
-- TG_smexf_bl30x25 has the highest return rate (34.43%), while
-- 210x110-squaredesign has the highest number of returns (32 orders).
-- These products should be prioritized for quality checks and root-cause analysis.





select * from FlipkartSales

