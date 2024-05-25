-- 1. Fetch all the paintings which are not displayed on any museums?
Select * from work where museum_id is null;

-- 2. Are there museums without any paintings?
select * from museum m
	where not exists (select 1 from work w
					 where w.museum_id=m.museum_id);
                     
-- 3. How many paintings have an asking price of more than their regular price?
select count(1) as count from product_size where sale_price>regular_price;

-- 4. Identify the paintings whose asking price is less than 50% of its regular price
select * from product_size p join work using(work_id) where sale_price < 0.5*regular_price;

-- 5. Which canva size costs the most?
with cte as (select size_id,sale_price as amount from product_size where sale_price = (select max(sale_price) from product_size))
select c.*,amount from cte join canvas_size c on cte.size_id = c.size_id;

-- 6. Delete duplicate records from work, product_size, subject and image_link tables
DELETE t1 FROM work t1
INNER JOIN work t2 
WHERE 
    t1.work_id > t2.work_id AND 
    t1.name = t2.name;
    
    
delete t1 from product_size t1
join product_size t2
where t1.work_id>t2.work_id and 
t1.size_id=t2.size_id and
t1.sale_price = t2.sale_price
and t1.regular_price = t2.regular_price;

-- 7. Identify the museums with invalid city information in the given dataset

select * from museum where city regexp '[a-zA-Z]';

-- 8. Museum_Hours table has 1 invalid entry. Identify it and remove it.
SET SQL_SAFE_UPDATES = 0;
delete from museum_hours where day='Thusday';
select distinct day from museum_hours;

-- 9. Fetch the top 10 most famous painting subject
select subject,count(1) from work w 
join subject s on w.work_id=s.work_id
group by subject 
order by count(1) desc limit 10;

-- 10. Identify the museums which are open on both Sunday and Monday. Display museum name, city.
select distinct m.name as museum_name, m.city, m.state,m.country
	from museum_hours mh 
	join museum m on m.museum_id=mh.museum_id
	where day='Sunday'
	and exists (select 1 from museum_hours mh2 
				where mh2.museum_id=mh.museum_id 
			    and mh2.day='Monday');


-- 11. How many museums are open every single day?
select count(1) from (select count(*) from museum_hours
group by museum_id
having count(*)=7) X;

-- 12. Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)
with top_5 as (select museum_id,count(1) as no_paintings from work w 
group by museum_id
order by count(1) desc limit 5)
select name,country,city, no_paintings from top_5 join museum m using(museum_id);

-- 13. Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
with top_5 as (select artist_id,count(1) as no_paintings from work w 
group by artist_id
order by count(1) desc limit 5)
select full_name,nationality,no_paintings from top_5 join artist m using(artist_id);
 
-- 14. Display the 3 least popular canva sizes

with top_3 as (select size_id,count(1) as no_of_paintigs from product_size
group by size_id
order by count(1) desc limit 3)
select * from canvas_size join top_3 using(size_id);

-- 15. Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?
select distinct museum_id, (time(str_to_date(close,'%h:%i:%p'))-time(str_to_date(open,'%h:%i:%p')))  from museum_hours;

-- 16. Which museum has the most no of most popular painting style?
with pop_style as (select style,count(1) as cnt from work
group by style
order by cnt desc limit 1),
museum_ as(
select museum_id,count(1) as no_of_paintings,p.style as style from work w join pop_style p on w.style = p.style group by museum_id,p.style
order by count(1) desc limit 1)
select name,style,no_of_paintings from museum_ m_ join museum m using(museum_id);

-- 17. Identify the artists whose paintings are displayed in multiple countries

with cte as
		(select distinct a.full_name as artist
		-- , w.name as painting, m.name as museum
		, m.country
		from work w
		join artist a on a.artist_id=w.artist_id
		join museum m on m.museum_id=w.museum_id)
	select artist,count(1) as no_of_countries
	from cte
	group by artist
	having count(1)>1
	order by 2 desc;

-- 18. Display the country and the city with most no of museums. Output 2 seperate
-- columns to mention the city and country. If there are multiple value, seperate them
-- with comma.
with cte_country as 
			(select country, count(1)
			, rank() over(order by count(1) desc) as rnk
			from museum
			group by country),
		cte_city as
			(select city, count(1)
			, rank() over(order by count(1) desc) as rnk
			from museum
			group by city)
	select group_concat(distinct country.country separator ',') as Country, group_concat(city.city separator ',') as City
	from cte_country country
	cross join cte_city city
	where country.rnk = 1
	and city.rnk = 1;

-- 19. Identify the artist and the museum where the most expensive and least expensive
-- painting is placed. Display the artist name, sale_price, painting name, museum
-- name, museum city and canvas label
with max_min as (select Max(sale_price) as max,min(sale_price) as min from product_size),
  max_min_found as (
select work_id,sale_price,label from canvas_size join product_size using(size_id) join max_min on sale_price in (max,min))
select full_name as artist,m.name as museum, w.name as painting,sale_price,m.city,label as canvas_label from work w 
join max_min_found using(work_id)
join artist a using(artist_id) 
join museum m using(museum_id);

-- 20. Which country has the 5th highest no of paintings?
with cte as (select country, count(1) as no_of_paintings, rank() over (order by count(1) desc) as rnk from work join museum using(museum_id)
group by country)
select country, no_of_paintings from cte where rnk=5;

-- 21. Which are the 3 most popular and 3 least popular painting styles?
with top_3
as (select style,count(1) as no_of_paintings, rank() over (order by count(1) desc) as rank_, count(1) over () as no_ from work where style not like '' group by style)
select style, case when rank_<=3 then 'Most Popular' else 'Least Popular' end as Popularity from top_3 where rank_<4 or rank_ > no_-3;

-- 22. Which artist has the most no of Portraits paintings outside USA?. Display artist
-- name, no of paintings and the artist nationality.

with cte as  (select artist_id,count(1) as no_of_paintings from subject join work w using(work_id) join museum using (museum_id) where country<>'USA' and subject='Portraits'
group by artist_id
order by no_of_paintings desc limit 1)
select full_name,nationality,no_of_paintings from artist join cte using(artist_id);
