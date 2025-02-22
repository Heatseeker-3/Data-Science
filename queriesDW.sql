 
select * from
(
    select f.product_id, p.product_name, sum(f.total_sale) as total_sale, 
            rank() over (order by sum(f.total_sale) desc) as rank
    from fact_sale f join dim_product p on p.product_id = f.product_id 
    group by  f.product_id, p.product_name) TAB
    where rank =1 
 ;

select * from
(
    select ds.supplier_id, ds.supplier_name,  sum(f.total_sale) as total_sale, 
            rank() over (order by sum(f.total_sale) desc) as rank
    from fact_sale f 
        inner join dim_supplier ds 
        on f.supplier_id=ds.supplier_id
        inner join dim_date d
        on f.t_date = d.t_date
    where d.t_year = 2016 and d.t_month = 8   
    group by  ds.supplier_id, ds.supplier_name) TAB
    where rank <=3 
 ;

select * from
(
    select st.store_id, st.store_name,  sum(f.total_sale) as total_sale, 
            rank() over (order by sum(f.total_sale) desc) as rank
    from fact_sale f 
        inner join dim_store st
        on f.store_id=st.store_id
        inner join dim_date d
        on f.t_date = d.t_date
    where d.t_year = 2016 and d.t_month = 8   
    group by  st.store_id, st.store_name) TAB
    where rank <=3 
 ; 


select count(*) as salesTransaction, sum(f.quantity) as quantitySold from
(
    select  f.product_id,  sum(f.total_sale) as total_sale, 
            rank() over (order by sum(f.total_sale) desc) as rank
    from fact_sale f 
        inner join dim_store st
        on f.store_id=st.store_id
        inner join dim_date d
        on f.t_date = d.t_date
    where d.t_year = 2016    
    group by   f.product_id) TAB, fact_sale f
    where tab.rank =1 and f.product_id = tab.product_id
 ;


--PRODUCT_NAME   Q1_2016   Q2_2016   Q3_2016   Q4_2016  
WITH   reportQuarterSale 
  AS
  (  
  select d.product_name, sum(f.total_sale) as total_sale, t.t_quarter
        from fact_sale f, dim_product d, dim_date t
        where f.product_id = d.product_id 
        and t.t_date = f.t_date
        and t.t_year = 2016
        group by d.product_name, t.t_quarter

)

select * from reportQuarterSale;
SELECT * 
  FROM
(
  SELECT product_name, 
         SUM(CASE WHEN t_quarter = 1 THEN total_sale END) q1_2016,
         SUM(CASE WHEN t_quarter = 2 THEN total_sale END) q2_2016,
         SUM(CASE WHEN t_quarter = 3 THEN total_sale END) q3_2016,
         SUM(CASE WHEN t_quarter = 4 THEN total_sale END) q4_2016
    FROM reportQuarterSale
   GROUP BY product_name
) ;

 
--STORE_ID           PROD_ID   STORE_TOTAL                 
DROP materialized VIEW STOREANALYSIS_MV;
CREATE materialized VIEW STOREANALYSIS_MV build  IMMEDIATE 
REFRESH COMPLETE
ENABLE QUERY REWRITE
AS
    SELECT f.store_id, f.product_id,
    SUM(f.total_sale) store_total
    FROM 
        fact_sale f
        GROUP BY f.store_id, f.product_id;
select * from storeanalysis_mv;

--ROLLUP
DROP materialized VIEW STOREANALYSIS_MV;
CREATE materialized VIEW STOREANALYSIS_MV build  IMMEDIATE 
REFRESH COMPLETE
ENABLE QUERY REWRITE
AS
    SELECT f.store_id, f.product_id,
    SUM(f.total_sale) store_total
    FROM      
        fact_sale f   
        GROUP BY ROLLUP (f.store_id, f.product_id)
        ORDER BY f.store_id, f.product_id;
select * from storeanalysis_mv;

--CUBE
DROP materialized VIEW STOREANALYSIS_MV;
CREATE materialized VIEW STOREANALYSIS_MV build  IMMEDIATE 
REFRESH COMPLETE
ENABLE QUERY REWRITE
AS
    SELECT f.store_id, f.product_id,
    SUM(f.total_sale) store_total
    FROM      
        fact_sale f   
        GROUP BY CUBE (f.store_id, f.product_id)
        ORDER BY f.store_id, f.product_id;
select * from storeanalysis_mv;


