-- 1
select count(*) as first_blood_in_1_3_min
from match
where first_blood_time > 60 and first_blood_time < 180
;
--2
select distinct  account_id
from players
inner join match on players.match_id = match.match_id
where account_id <> 0 and positive_votes > negative_votes and radiant_win = 'True'
order by account_id
;
--3
select  account_id, cast(avg(duration) as numeric (4, 0))
from players
inner join match on players.match_id = match.match_id
where account_id <> 0
group by account_id
order by account_id
;
--4
select   sum(gold_spent) as sum_gold_spent, count(distinct(hero_id)) as num_of_heroes, cast(avg(duration) as numeric(4,0)) as avg_duration
from players
inner join match on players.match_id = match.match_id
where account_id = 0
;
--5
select localized_name, count(match.match_id) as matches, cast(avg(kills) as numeric(4,2)) as avg_kills, min(deaths) as min_deaths, max(gold_spent) as max_gold_spent, sum(positive_votes) as pos_votes, sum(negative_votes) as neg_votes
from hero_names
inner join players on hero_names.hero_id = players.hero_id
inner join match on players.match_id = match.match_id
group by localized_name
order by localized_name
;
--6
select distinct match.match_id
from match
inner join purchase_log on match.match_id = purchase_log.match_id
where item_id = 42 and time > 100
order by match_id
;
--7
select *
from match, purchase_log limit 20
;
--8 вывести топ-10 героев, которые которые чаще всего брались в катках, где побеждали силы света, и вывести сколько раз брались.
select count(match.match_id) as freq,  localized_name
from match inner join players on match.match_id = players.match_id
inner join hero_names  on players.hero_id = hero_names.hero_id
where radiant_win = 'True'
group by  localized_name
order by freq desc limit 10;

--9 вывести количество побед света (true) и тьмы (false), матчи между которыми были сыграны на серверах Бразилии
select count(match_id), radiant_win
from match inner join cluster_regions on match.cluster = cluster_regions.cluster
where region = 'BRAZIL'
group by radiant_win
;
--10 вывести неанонимных игроков, в порядке убывания количества убийств, а в случае равеноства по возрастанию смертей
select account_id, sum(kills) k, sum(deaths) d
from players
where account_id != 0
group by  account_id
order by k desc, d asc
;
--11 вывести айдишники топовых игроков на серверах Америки по винрейту, количеству побед, которые поучаствовали более чем в 50 матчах
select distinct players.account_id, round(cast(total_wins as decimal(5,2)) / total_matches, 2)  winrate, total_wins, total_matches
from players inner join player_ratings pr on players.account_id = pr.account_id
inner join match on players.match_id = match.match_id
inner join cluster_regions cr on match.cluster = cr.cluster
where (region = 'US EAST' or region = 'US WEST') and total_matches > 50
order by winrate desc, total_matches desc, account_id asc
;