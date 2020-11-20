--Проверим гипотезу: в матчах, где участвовали 20% самых скиловых по винрейту игроков (винрейт - отношения побед к матчам игрока. Считаются
--только игроки, у которых больше 50 матчей) чем раньше случалась первая кровь, тем меньше длился матч

--cte считает винрейт всех игроков
with  cte as
(select  match.match_id, players.account_id, round(cast(total_wins as decimal(5,2)) / total_matches, 2)  as winrate, total_wins, total_matches,
                 first_blood_time, duration
from players inner join player_ratings pr on players.account_id = pr.account_id
inner join match on players.match_id = match.match_id
where (total_matches > 50)
order by winrate desc, total_matches desc, account_id asc)

--Находим 0,8-перцентиль. Видим, что он равен 0.57
select round(cast(percentile_cont(0.8)  within group(order by winrate) as decimal (6,2)), 2) as "20% of players have winrate more than"
from cte;

--Перекопировал верхнюю cte
with  cte as
(select  match.match_id, players.account_id, round(cast(total_wins as decimal(5,2)) / total_matches, 2)  as winrate, total_wins, total_matches,
                 first_blood_time, duration
from players inner join player_ratings pr on players.account_id = pr.account_id
inner join match on players.match_id = match.match_id
where (total_matches > 50)
order by winrate desc, total_matches desc, account_id asc),

--Считаем среднюю продолжительность матчей для каждого first blood, где были игроки с необходимым винрейтом
cte2 as (select distinct  first_blood_time,  avg(duration) over (partition by first_blood_time) as avg_duration
from cte
where (winrate > 0.53)
order by first_blood_time),

--Считаем разницу между first blood последующей и предыдущей секунды
cte3 as (
    select *, avg_duration - lead(avg_duration) over(order by first_blood_time )  as difference
from cte2
order by first_blood_time)

--Считаем сколько положительных разностей (их 145). Нашу гипотезу подтвердит наличие всех плюсов. Плюсов 145, а всего строк там 291.
select count(difference)
from cte3
where difference > 0
--Таким образом, гипотеза не подтверждена.