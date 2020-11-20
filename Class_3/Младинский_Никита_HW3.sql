--1 Как видно, наибольшая потеря клиентов происходит на этапе назначения водителя (сам сталкивался, иногда очень долго ищет) и на этапе подачи машины (тоже сталкивался, иногда водители просто не едут к тебе, чтобы вынудить отменить самому не выгодный им заказ)
select tariff,
       count(idhash_view),
       count(idhash_order),
       count(da_dttm),
       count(rfc_dttm),
       count(cc_dttm),
       count(finish_dttm)
from orders
any inner join views using idhash_order
group by tariff
;

--2
select  idhash_client,
        groupArray(tariff) top,
        groupArray(c) top_count,
        length(top) nmb_tariffs
 from
        (select idhash_client, tariff, count(tariff) c
        from views
        group by idhash_client, tariff
        order by idhash_client asc, c desc )
group by idhash_client
order by idhash_client
;

--3 Сделал в одном запросе топ-10 по отправке и топ-10 финишу
--Насчет условия в каунте: использую функцию, которая берет час даты. но надо отдельно дописать случай последнего часа, потому что 10:00 это 10 час, но из него подходит только это время
select geoToH3(longitude, latitude, 7) as h3,
       countIf(cc_dttm, status = 'CP' and (toHour(cc_dttm) >= 7 and toHour(cc_dttm) <=9 or (toHour(cc_dttm) == 10 and toMinute(cc_dttm) == 0 and toSecond(cc_dttm) == 0))) cnt,
       '  уезжают с 7 до 10' as commentary
from views
any inner join orders using idhash_order
group by h3
order by cnt desc
limit 10
union all
select geoToH3(del_longitude, del_latitude, 7) as h3,
       countIf(finish_dttm, status = 'CP' and (toHour(cc_dttm) >= 18 and toHour(cc_dttm) <=19 or (toHour(cc_dttm) == 20 and toMinute(cc_dttm) == 0 and toSecond(cc_dttm) == 0))) cnt,
       '  приезжают с 18 до 20' as commentary
from views
any inner join orders using idhash_order
group by h3
order by cnt desc
limit 10
;
--4
select quantilesExact(0.5, 0.95)(dif) as median_and_095quantile
from
        (select order_dttm,
                da_dttm,
                datediff('minute', order_dttm,da_dttm) dif
        from orders
        where dif is not null)
;
--5
select id_string
from
    (select toString(idhash_client) id_string,
            countIf(tariff, tariff == 'Бизнес') cnt
    from views
    group by idhash_client)
where cnt >= 1 and position(id_string, '57') != 0
