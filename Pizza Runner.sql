
--Data cleaning for null values

UPDATE customer_orders SET exclusions = NULL WHERE exclusions IN ('null', '')
UPDATE customer_orders SET extras = NULL WHERE extras IN ('null', '')
UPDATE runner_orders SET cancellation = NULL WHERE cancellation IN ('null', '')


--1. How many pizzas were ordered?

SELECT COUNT(pizza_id)
FROM customer_orders


--2. How many unique customer orders were made?

SELECT COUNT(DISTINCT customer_id)
FROM customer_orders


--3. How many successful orders were delivered by each runner?

SELECT runner_id,
COUNT(runner_id)
FROM runner_orders
WHERE pickup_time != 'null'
GROUP BY 1


--4. How many of each type of pizza was delivered?

SELECT pizza_id, COUNT(pizza_id)
FROM runner_orders as r
LEFT JOIN customer_orders as c
ON r.order_id=c.order_id
WHERE pickup_time != 'null'
GROUP BY 1



--5. How many Vegetarian and Meatlovers were ordered by each customer?

SELECT customer_id, pizza_name, COUNT(pizza_name)
FROM customer_orders as c
LEFT JOIN pizza_names as p
ON c.pizza_id=p.pizza_id
GROUP BY 1,2
ORDER BY 1,2



--6. What was the maximum number of pizzas delivered in a single order?

SELECT r.order_id, COUNT(pizza_id)
FROM runner_orders as r
LEFT JOIN customer_orders as c
ON r.order_id=c.order_id
WHERE pickup_time != 'null'
GROUP BY 1
ORDER BY 2 desc
LIMIT 1




--7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

WITH tablo AS
(
SELECT *,  
CASE WHEN exclusions is not null OR extras is not null THEN 'yes'
ELSE 'no'
END AS  change
FROM customer_orders
)
SELECT customer_id, change, COUNT(change)
FROM tablo
GROUP BY 1,2 
ORDER BY 1,2



--8. How many pizzas were delivered that had both exclusions and extras?

WITH tablo AS
(
SELECT *,
CASE WHEN exclusions is not null AND extras is not null THEN 'yes'
ELSE 'no'
END AS  change
FROM runner_orders as r
LEFT JOIN customer_orders as c
ON r.order_id=c.order_id
WHERE pickup_time != 'null' 
)
SELECT COUNT(change)
FROM tablo
WHERE change='yes'



--9. What was the total volume of pizzas ordered for each hour of the day?

WITH tablo AS
(
SELECT *,
EXTRACT(DAY from order_time) as day,
EXTRACT(HOUR from order_time) as hour
FROM customer_orders
)
SELECT day, hour, COUNT(pizza_id)
FROM tablo
GROUP BY 1,2
ORDER BY 1,2



--10. What was the volume of orders for each day of the week?

WITH tablo AS
(
SELECT *,
EXTRACT(DAY from order_time) as day,
EXTRACT(WEEK from order_time) as week
FROM customer_orders
)
SELECT week, day, COUNT(pizza_id)
FROM tablo
GROUP BY 1,2
ORDER BY 1,2


--11. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

WITH tablo as
(
SELECT *,
EXTRACT(WEEK from registration_date) as week
FROM runners
)
SELECT week, COUNT(runner_id)
FROM tablo
GROUP BY 1



--12. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

with tablo as
(
select runner_id, split_part(duration,'m',1)::int as duration from runner_orders
where cancellation is null
)
select runner_id, round(avg(duration)) as avg_duration
from tablo
group by 1



--13. Is there any relationship between the number of pizzas and how long the order takes to prepare?

select pizza_id, order_time, pickup_time::timestamp,
pickup_time::timestamp-order_time as preparation_time
from customer_orders as c
left join runner_orders as r
on c.order_id=r.order_id
where cancellation is null
order by 1



--14. What was the average distance travelled for each customer?

with tablo as
(
select customer_id, split_part(distance,'k',1)::float as distance 
from runner_orders as r
join customer_orders as c
on r.order_id=c.order_id
where cancellation is null
)
select customer_id, round(avg(distance)) as avg_distance
from tablo
group by 1



--15. What was the difference between the longest and shortest delivery times for all orders?


with tablo as
(
select split_part(duration,'m',1)::int as duration from runner_orders
where cancellation is null
)
select max(duration)-min(duration) from tablo



--16. What was the average speed for each runner for each delivery and do you notice any trend for these values?


with tablo as
(
select order_id, runner_id, 
(split_part(duration,'m',1)::int)/60::decimal as duration,
split_part(distance,'k',1)::float as distance 
from runner_orders
where cancellation is null
)

select order_id, runner_id,
round(distance/duration) as avg_speed
from tablo



--17. What is the successful delivery percentage for each runner?


with tablo2 as
(
with tablo as
(
select runner_id,
count(runner_id)
from runner_orders
where cancellation is null
group by 1
)
select *,
sum(count) over()
from tablo
)
select runner_id,
round((count/sum)*100) as percentage
from tablo2













