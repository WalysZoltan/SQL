/*
Подключение:

user - student, password - nUrHdn2N
89.208.84.253 port - 58123
*/

-- 22

select tariff
     , uniqExact(idhash_view)                   as v
     , uniqExact(idhash_order)                  as o
     , uniqExact(idhash_client)                 as cl
     , sumIf(client_bill_usd, idhash_order > 0) as amount_client_bill
     , amount_client_bill / o                   as avg_client_bill

from data_analysis.views
group by tariff


-- 24

select tariff
     , uniqExact(idhash_view)                                                as v
     , uniq(idhash_view)                                                     as v_u
     , uniqExact(idhash_order)                                               as o
     , uniq(idhash_order)                                                    as o_u
     , uniqExact(idhash_client)                                              as cl
     , sumIf(client_bill_usd, idhash_order > 0)                              as amount_client_bill
     , avgIf(client_bill_usd, idhash_order > 0)                              as avg_client_bill
     , medianIf(client_bill_usd, idhash_order > 0)                           as median_client_bill
     , quantilesExactIf(0.75, 0.95, 0.99)(client_bill_usd, idhash_order > 0) as quan_clients_bill
     , maxIf(client_bill_usd, idhash_order > 0)                              as max_client_bill

from data_analysis.views
group by tariff
;

-- 25

select uniqExact(idhash_view) as v
     , avg(client_bill_usd)   as avg_clb
from data_analysis.views
;

select uniqMerge(v_pre_agg) as v
     , avgMerge(cb_pre_agg) as avg_client_bill
from (select uniqState(idhash_view)    as v_pre_agg
           , avgState(client_bill_usd) as cb_pre_agg

      from data_analysis.views)

;
-- 28
-- к началу 5 минутки
select toStartOfFiveMinute(now()) as dt1
union all
-- к началу 15 минутки
select toStartOfFifteenMinutes(now()) as dt2
union all
-- начало часа
select toStartOfHour(now()) as dt3
union all
-- начало дня
select toStartOfDay(now()) as dt4
union all
-- начало недели
select toStartOfWeek(now()) as dt5
union all
-- начало месяца
select toStartOfMonth(now()) as dt6
union all
-- начало года
select toStartOfYear(now()) as dt7
;
--29
select toStartOfFifteenMinutes(order_dttm) as order_dttm15
     , uniqExact(idhash_order)             as orders
from data_analysis.orders
group by order_dttm15
order by order_dttm15
limit 100
;
-- 30

select toStartOfFifteenMinutes(order_dttm)              as order_dttm15
     , uniqExact(idhash_order)                          as orders
     , avg(dateDiff('minute', order_dttm, finish_dttm)) as average_trip_duration

from data_analysis.orders
where status = 'CP'
group by order_dttm15
order by order_dttm15
limit 100

-- 32
select if(cancel_dttm > 0, 'Отменил клиент', 'Не отменял')                as client_cancel
     , multiIf(cancel_dttm > 0 and da_dttm is null, 'До назначения',
               cancel_dttm > 0 and da_dttm > 0, 'После назначения', null) as when_cancel
     , uniqExact(idhash_order)                                            as orders

from data_analysis.orders
group by client_cancel, when_cancel
;

-- 34

SELECT order_date
       , max(runningDifference(order_dttm)) as diff
from (
      SELECT toDate(order_dttm) as order_date
           , order_dttm
      from data_analysis.orders
      order by order_dttm
         )
group by order_date
;
-- 36
select tariff
     , groupArray(order_dt)                                                    as o_dt
     , groupArray(orders)                                                      as gr_orders
     , arrayReverseSort(gr_orders)                                             as orders_desc
     , arrayElement(orders_desc, 1)                                            as max_orders
     , arrayElement(groupArray(order_dt),
                    indexOf(groupArray(orders), arrayElement(orders_desc, 1))) as date_max_orders
from (select tariff
           , uniqExact(idhash_order) as orders
           , toDate(order_dttm)      as order_dt
      from data_analysis.orders as o
               any
               inner join (select idhash_client
                                , idhash_order
                                , tariff
                           from data_analysis.views
                           where idhash_order > 0) as v using idhash_order
      where status = 'CP'
      group by tariff, order_dt)
group by tariff

-- 37

select tariff
     , o_dt
     , gr_orders
     , orders_desc
     , max_orders
     , date_max_orders
     , multiIf(tariff = 'Бизнес', arraySum(x -> x > (max_orders * 0.8), gr_orders),
               tariff = 'Эконом', arraySum(x -> x > (max_orders * 0.8), gr_orders),
               tariff = 'Комфорт+', arraySum(x -> x > (max_orders * 0.8), gr_orders),
               tariff = 'Комфорт', arraySum(x -> x > (max_orders * 0.8), gr_orders), null) as multiif_sum

from (select tariff
           , groupArray(order_dt)                                                    as o_dt
           , groupArray(orders)                                                      as gr_orders
           , arrayReverseSort(gr_orders)                                             as orders_desc
           , arrayElement(orders_desc, 1)                                            as max_orders
           , arrayElement(groupArray(order_dt),
                          indexOf(groupArray(orders), arrayElement(orders_desc, 1))) as date_max_orders
      from (select tariff
                 , uniqExact(idhash_order) as orders
                 , toDate(order_dttm)      as order_dt
            from data_analysis.orders as o
                     any
                     inner join (select idhash_client
                                      , idhash_order
                                      , tariff
                                 from data_analysis.views
                                 where idhash_order > 0) as v using idhash_order
            where status = 'CP'
            group by tariff, order_dt)
      group by tariff)
;

-- 38

select idhash_client
           , groupArray(order_dttm)   as o
           , groupArray(idhash_order) as o_id
           , arrayEnumerate(o_id)     as rn
      from (select idhash_client
                 , order_dttm
                 , idhash_order

            from data_analysis.orders
                     any
                     inner join (select idhash_client
                                      , idhash_order
                                      , tariff
                                 from data_analysis.views
                                 where idhash_order > 0) as v using idhash_order
            where status = 'CP'
            order by order_dttm)
      group by idhash_client


-- 41

select toStartOfHour(view_dttm)        as view_dttm_h,
       geoToH3(longitude, latitude, 7) as h3,
       uniqExact(idhash_view)          as views,
       uniqExact(idhash_order)         as orders
from data_analysis.views
group by view_dttm_h, h3
;

-- 42

select case
           when pointInPolygon(tuple(assumeNotNull(ifNull(latitude, 0)),
                                     assumeNotNull(ifNull(longitude, 0))),
                               [(57.630289774902636, 39.85046746220826),
                                   (57.62284477742168, 39.865745324757086),
                                   (57.630473582697384, 39.883769769337164),
                                   (57.63837643789073, 39.869521875050054)])
               then 'Центр'
           else 'не центр' end as polyg
     , uniqExact(idhash_view)  as views
     , uniqExact(idhash_order) as orders
from data_analysis.views
group by polyg
;
