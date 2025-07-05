-- 1) How many matches did each team play?

with filtered_ipl as (
	select * from ipl
	where "Winning Team" not in ('Rain Interrupted (No Result)')
	and "Winning Team" notnull
)

select team as "Team", count(*) as "Matches Played" from (
	select "Home Team" as team from filtered_ipl
		union all
	select "Away Team" as team from filtered_ipl
) as all_teams
group by team
order by count(*) desc

-- 2) Which venue hosted the most number of matches?

select "Venue", count(*) as "Matches Played" from ipl group by "Venue" order by "Matches Played" desc

-- 3) What was the win ratio of each team? (Wins/Matches Played)

with total_matches as (
	
	select team, count(*) AS matches_played
	from (
		select "Home Team" as team from ipl where "Winning Team" not in ('Rain Interrupted (No Result)','Tie') and "Winning Team" notnull union all
		select "Away Team" as team from ipl where "Winning Team" not in ('Rain Interrupted (No Result)','Tie') and "Winning Team" notnull
	) as all_matches

	group by team
	
),

team_wins as (
	select "Winning Team" as team, count(*) as wins from ipl
	where "Winning Team" NOT IN ('_','Rain Interrupted (No Result)','-')
	group by "Winning Team"
)

select
	team_wins.team as "Team",
	total_matches.matches_played as "Total Matches Played",
	team_wins.wins as "Wins",
	round((team_wins.wins*100.0)/total_matches.matches_played,2) as "Win Percent"
from team_wins
join total_matches on team_wins.team = total_matches.team
order by "Win Percent" desc

-- 4) What percentage of matches were won by chasing vs. defending?

with winning_category as (

	select
	
		SUM(CASE 
			WHEN "Toss Winner" = "Winning Team" AND "Toss Decision" = 'Bat First' THEN 1
			WHEN "Toss Winner" != "Winning Team" AND "Toss Decision" = 'Bowl First' THEN 1
			ELSE 0
		END) AS batting_first_wins,

		SUM(CASE 
			WHEN "Toss Winner" = "Winning Team" AND "Toss Decision" = 'Bowl First' THEN 1
			WHEN "Toss Winner" != "Winning Team" AND "Toss Decision" = 'Bat First' THEN 1
			ELSE 0
		END) AS bowling_first_wins,

		count(*) as total_matches
	
	from ipl
	WHERE "Winning Team" NOT IN ('-', 'Rain Interrupted (No Result)') and "Winning Team" notnull
	
)
	
select 
	winning_category.batting_first_wins as "Batting First", winning_category.bowling_first_wins as "Bowling First",
	round(winning_category.batting_first_wins*100.0/winning_category.total_matches,2) as "Batting First Win %",
	round(winning_category.bowling_first_wins*100.0/winning_category.total_matches,2) as "Bowling First Win %"
FROM winning_category

-- 5) How many Single and Double Headers were conducted in the season?

with match_number_stats as (
	select "Date", count(*) as matches_count from ipl
	where "Winning Team" notnull
	group by "Date"
),

matches_day_type as (

	select 
	
		sum(case
			when match_number_stats.matches_count = 1 then 1
			else 0
		end )  as single_headers,
		
		sum(case
			when match_number_stats.matches_count = 2 then 1
			else 0
		end ) as double_headers
	
	from match_number_stats

)

select 
	matches_day_type.single_headers as "Single Headers",
	matches_day_type.double_headers as "Double Headers"
from matches_day_type;

-- 6) How often did the toss winner win the match and winning percent if a team wins the toss?

with toss_the_boss as (

	select
	
		sum(case
			when "Toss Winner" = "Winning Team" then 1
			else 0
		end ) as toss_wins_matches,
	
		sum(case
			when "Toss Winner" != "Winning Team" then 1
			else 0
		end ) as toss_lost_matches,
	
	count(*) as total_tosses
	
	from ipl
	where "Toss Winner" notnull
	and "Winning Team" NOT IN ('Rain Interruped (No Result)','Tie') and "Winning Team" notnull

)

select
	toss_the_boss.toss_wins_matches as "Toss Won and Match Won",
	toss_the_boss.toss_lost_matches as "Toss Won but Match Lost",
	round(toss_the_boss.toss_wins_matches*100.0/toss_the_boss.total_tosses,2) as "Toss Win Match Win %"
from toss_the_boss

-- 7) What is the win rate for teams choosing to bat first vs bowl first?

with teams as (
	select "Home Team" as team, "Match Number" as match_number from ipl where "Winning Team" not in ('Rain Interrupted (No Result)','Tie') and "Winning Team" notnull union
	select "Away Team" as team, "Match Number" as match_number from ipl where "Winning Team" not in ('Rain Interrupted (No Result)','Tie') and "Winning Team" notnull
),

team_toss_decision_category as (

	select teams.team,
	
		sum(case
			when teams.team = "Toss Winner" and "Toss Decision" = 'Bat First' then 1
			when teams.team != "Toss Winner" and "Toss Decision" = 'Bowl First' then 1
			else 0
		end) as bat_first,
	
		sum(case
			when teams.team = "Toss Winner" and "Toss Decision" = 'Bat First' and "Winning Team" = teams.team then 1
			when teams.team != "Toss Winner" and "Toss Decision" = 'Bowl First' and "Winning Team" = teams.team then 1
			else 0
		end) as bat_first_won,
		
		sum(case
			when teams.team = "Toss Winner" and "Toss Decision" = 'Bowl First' then 1
			when teams.team != "Toss Winner" and "Toss Decision" = 'Bat First' then 1
			else 0
		end) as bowl_first,
	
		sum(case
			when teams.team = "Toss Winner" and "Toss Decision" = 'Bowl First' and "Winning Team" = teams.team then 1
			when teams.team != "Toss Winner" and "Toss Decision" = 'Bat First' and "Winning Team" = teams.team then 1
			else 0
		end) as bowl_first_won
		
		from ipl
		join teams on "Match Number" = teams.match_number
		where "Toss Decision" NOT IN ('_','-','Rain Interrupted (No Result)')
		group by teams.team

)

select 
	team as "Team",
	bat_first as "Bat First Count",
	bowl_first as "Bowl First Count",
	bat_first_won as "Won while Batting First",
	bowl_first_won as "Won while Bowling First",
	round(bat_first_won*100/bat_first,2) as "Batting first Win %",
	round(bowl_first_won*100/bowl_first,2) as "Bowling first win %"
from team_toss_decision_category

-- 8) Which team had the highest toss win rate?

with teams as (
	select "Home Team" as team, "Match Number" as match_number from ipl union
	select "Away Team" as team, "Match Number" as match_number from ipl
),

toss_win_stats as (

	select teams.team as team,
	
	sum(case
		when teams.team = "Toss Winner" then 1
		else 0
	end ) as toss_wins,
	
	count(*) as total_matches
	
	from ipl
	join teams on teams.match_number = "Match Number"
	where "Winning Team" not in ('Rain Interrupted (No Result)','Tie') and "Winning Team" notnull
	group by teams.team

)

select 
	team as "Team",
	total_matches as "Matches Played",
	toss_wins as "Tosses Won",
	round(toss_wins*100.0/total_matches,2) as "Toss Win %"
from toss_win_stats
order by toss_wins desc

-- 9) What are the average scores when batting first vs second?

with teams as (
	select "Home Team" as team, "Match Number" as match_number from ipl union
	select "Away Team" as team, "Match Number" as match_number from ipl
),

filtered_ipl as (
	select * from ipl
	where "Home Team Score" > 0
	and "Away Team Score" > 0
	and "Winning Team" not in ('Rain Interrupted (No Result)','Tie')
	and "Winning Team" notnull
),

average_scores as (

	select
	
	sum (case
		 when team = "Toss Winner" and "Toss Decision" = 'Bat First' then cast("Home Team Score" as integer)
		 when team != "Toss Winner" and "Toss Decision" = 'Bowl First' then cast("Away Team Score" as integer)
		 else 0
	end ) as batting_first_total,
	
	sum (case
		 when team = "Toss Winner" and "Toss Decision" = 'Bat First' then 1
		 when team != "Toss Winner" and "Toss Decision" = 'Bowl First' then 1
		 else 0
	end ) as batting_first_count,
	
	sum (case
		 when team = "Toss Winner" and "Toss Decision" = 'Bowl First' then cast("Home Team Score" as integer)
		 when team != "Toss Winner" and "Toss Decision" = 'Bat First' then cast("Away Team Score" as integer)
		 else 0
	end ) as batting_second_total,
	
	sum (case
		 when team = "Toss Winner" and "Toss Decision" = 'Bowl First' then 1
		 when team != "Toss Winner" and "Toss Decision" = 'Bat First' then 1
		 else 0
	end ) as batting_second_count
	
	from filtered_ipl
	join teams on teams.match_number = "Match Number"

)

select
	round(batting_first_total*1.0/batting_first_count,2) as "Batting First Avg. Score",
	round(batting_second_total/batting_second_count,2) as "Batting Second Avg. Score"
from average_scores

-- 10) What is the average run rate for each team?

with filtered_ipl as (
	select * from ipl
	where "Home Team Run Rate" > 0
	and "Away Team Run Rate" > 0
	and "Winning Team" NOT IN ('-','_','Rain Interrupted (No Result)')
	and "Winning Team" notnull
),

teams as (
	select "Home Team" as team, "Match Number" as match_number from ipl
		union
	select "Away Team" as team, "Match Number" as match_number from ipl
),

run_rate_stats as (

	select teams.team as team,
	
	sum (case
			when teams.team = "Home Team" then cast("Home Team Run Rate" as float)
			else 0
		end ) as run_rate_as_home_team,
	
	sum (case
			when teams.team = "Away Team" then cast("Away Team Run Rate" as float)
			else 0
		end ) as run_rate_as_away_team
	
	from filtered_ipl
	join teams on teams.match_number = "Match Number"
	group by team

),

team_matches as (

	select team, count(*) as matches from (
		select "Home Team" as team from filtered_ipl
			union all
		select "Away Team" as team from filtered_ipl
		) as all_teams
	group by team

)

select
	run_rate_stats.team as "Team",
	matches as "Matches Played",
	round(((run_rate_as_home_team + run_rate_as_away_team) / matches)::numeric, 2) as "Average Run Rate"
from run_rate_stats
join team_matches on team_matches.team = run_rate_stats.team
order by "Average Run Rate" desc

-- 11) What is the average number of wickets lost by each team?

with filtered_ipl as (
	select * from ipl
	where "Home Team Wickets Fallen" > 0
	and "Away Team Wickets Fallen" > 0
	and "Winning Team" not in ('Rain Interrupted (No Result)','Tie')
	and "Winning Team" notnull
),

teams as (
	select team, match_number from (
		select "Home Team" as team, "Match Number" as match_number from filtered_ipl
			union
		select "Away Team" as team, "Match Number" as match_number from filtered_ipl
	) all_matches
),

home_wickets_fallen as (
	select 
		teams.team as team, 
		count(*) as matches_played,
		sum(cast("Home Team Wickets Fallen" as float)) as home_wickets 
	from filtered_ipl
	join teams on teams.match_number = "Match Number"
	where "Home Team" = teams.team
	group by team
),

away_wickets_fallen as (
	select 
		teams.team as team,
		count(*) as matches_played,
		sum(cast("Away Team Wickets Fallen" as float)) as away_wickets
	from filtered_ipl
	join teams on teams.match_number = "Match Number"
	where "Away Team" = teams.team
	group by team
),

total_wickets as (
	select 
		home_wickets_fallen.team, 
		home_wickets_fallen.matches_played as hm, 
		away_wickets_fallen.matches_played as am,
		home_wickets, away_wickets_fallen.away_wickets as away_wickets
	from home_wickets_fallen 
	join away_wickets_fallen on away_wickets_fallen.team = home_wickets_fallen.team
)

select team as "Team", round(((home_wickets+away_wickets)/(hm+am))::numeric,2) as "Average Wickets Fallen Per Match" from total_wickets
order by "Average Wickets Fallen Per Match" desc

-- 12) What is the highest team total of the season?

with filtered_ipl as (
	select * from ipl
	where "Home Team Score" > 0
	and "Away Team Score" > 0
	and "Winning Team" not in ('Rain Interrupted (No Result)','Tie')
	and "Winning Team" notnull
),

teams as (
	select "Home Team" as team, cast("Home Team Score" as integer) as max_score from filtered_ipl
		union
	select "Away Team" as team, cast("Away Team Score" as integer) as max_score from filtered_ipl
)

select
	team as "Team",
	max(max_score) as "High Score"
from teams
group by team
order by "High Score" desc

-- 13) Which team scored the most runs in the first 6 overs?

with filtered_overwise as (
	select * from "ipl-overwise" o
	where "Home Team Score" > 0
	and "Away Team Score" > 0
	and exists (
		select * from ipl i
		where "Winning Team" not in ('Rain Interrupted (No Result)','Tie')
		and "Winning Team" notnull
		and i."Match Number" = o."Match Number"
	)
),

teams as (
	select team, match_number from (
		select "Home Team" as team, "Match Number" as match_number from filtered_overwise
			union
		select "Away Team" as team, "Match Number" as match_number from filtered_overwise
	) as all_teams
),

hometeampp as (
	select teams.team as team, max("Home Team Score") as homemax from filtered_overwise
	join teams on teams.match_number = "Match Number"
	where teams.team = "Home Team" and "Over Number" = 6
	group by teams.team
),

awayteampp as (
	select teams.team, max("Away Team Score") as awaymax from filtered_overwise
	join teams on teams.match_number = "Match Number"
	where teams.team = "Away Team" and "Over Number" = 6
	group by teams.team
),

maxscorepp as (
	select hometeampp.team as team, greatest(homemax,awayteampp.awaymax) as max_pp_score from hometeampp
	join awayteampp on awayteampp.team = hometeampp.team
)

select team as "Team", max_pp_score as "Highest Powerplay Score" from maxscorepp order by "Highest Powerplay Score" desc

-- 14) Which team conceded the least runs in the death overs (Overs: 16-20)?

with filtered_ipl as (
	select * from "ipl-overwise" o
	where "Home Team Score" > 0
	and "Away Team Score" > 0
	and exists (
		select * from ipl i
		where "Winning Team" not in ('Rain Interrupted (No Result)','Tie')
		and "Winning Team" notnull
		and i."Match Number" = o."Match Number"
	)
),

teams as (
	select team, count(*) as matches_played from (
		select "Home Team" as team, "Winning Team" from ipl
		where "Winning Team" not in ('Rain Interrupted (No Result)','Tie')
		and "Winning Team" notnull
			union all
		select "Away Team" as team, "Winning Team" from ipl
		where "Winning Team" not in ('Rain Interrupted (No Result)','Tie')
		and "Winning Team" notnull
	) as all_matches
	group by team
),

homedeathover as (
	select teams.team as t,
		sum(case
		   	when teams.team = "Home Team" and "Over Number" between 16 and 20 then cast("Away Team Runs Scored" as float)
		end ) as home_death_over_runs
	from filtered_ipl
	join teams on teams.team = "Home Team"
	group by teams.team
),

awaydeathover as (
	select teams.team as t,
		sum(case
		   	when teams.team = "Away Team" and "Over Number" between 16 and 20 then cast("Home Team Runs Scored" as float)
		end ) as away_death_over_runs
	from filtered_ipl
	join teams on teams.team = "Away Team"
	group by teams.team
),

leastruns_deathover as (
	select homedeathover.t, (home_death_over_runs+awaydeathover.away_death_over_runs) as least_death_over_runs 
	from homedeathover
	join awaydeathover on awaydeathover.t = homedeathover.t
)

select 
	t as "Team", teams.matches_played as "Total Matches",
	least_death_over_runs as "Total Runs Conceded in Death Overs",
	round((least_death_over_runs/teams.matches_played)::numeric,2) as "Average Runs Conceded in Death Overs"
	from leastruns_deathover 
	join teams on teams.team = t
	order by "Average Runs Conceded in Death Overs"
	
-- 15) Which team had the best economy rate overall?

with filter_ipl as (
	select * from "ipl-overwise" o
	where "Home Team Score" > 0
	and "Away Team Score" > 0
	and exists (
		select * from ipl i
		where i."Match Number" = o."Match Number"
		and "Winning Team" not in ('Rain Interrupted (No Result)','Tie') and "Winning Team" notnull
	)
),

teams as (
	select team, count(*) as matches_played from (
		select "Home Team" as team from ipl where "Winning Team" not in ('Rain Interrupted (No Result)','Tie') and "Winning Team" notnull
			union all
		select "Away Team" as team from ipl where "Winning Team" not in ('Rain Interrupted (No Result)','Tie') and "Winning Team" notnull
	) as all_matches
	group by team
),

homeconcede as (
	select
		teams.team as t,
		sum(case
		   	when teams.team = "Home Team" and "Over Number" > 0 then cast("Away Team Runs Scored" as float)
		end ) as hometotal
	from filter_ipl
	join teams on teams.team = "Home Team"
	group by t
),

awayconcede as (
	select
		teams.team as t,
		sum(case
		   	when teams.team = "Away Team" and "Over Number" > 0 then cast("Home Team Runs Scored" as float)
		end ) as awaytotal
	from filter_ipl
	join teams on teams.team = "Away Team"
	group by t
),

leasteconomy as (
	select 
		homeconcede.t as team, 
		hometotal as "Runs Conceded at Home Venue",
		awaytotal as "Runs Conceded at Away Venue",
		(hometotal+awayconcede.awaytotal) as "Total Runs Conceded"
	from homeconcede
	join awayconcede on awayconcede.t = homeconcede.t
),

homeoversbowled as (
	select "Home Team" as team, "Match Number", max("Over Number") as overs_bowled
	from filter_ipl
	group by team, "Match Number"
),

awayoversbowled as (
	select "Away Team" as team, "Match Number", max("Over Number") as overs_bowled
	from filter_ipl
	group by team, "Match Number"
),

totalovers as (
	select team, sum(overs_bowled) as home_overs from homeoversbowled group by team
		union all
	select team, sum(overs_bowled) as away_overs from awayoversbowled group by team
),

combinedovers as (
	select team, sum(home_overs) as total_overs
	from totalovers
	group by team
)

select 
	leasteconomy.team as "Team",
	teams.matches_played as "Matches Played",
	"Runs Conceded at Home Venue",
	"Runs Conceded at Away Venue",
	"Total Runs Conceded",
	combinedovers.total_overs as "Total Overs Bowled",
	round((("Total Runs Conceded")/combinedovers.total_overs)::numeric,2) as "Average Economy"
from leasteconomy
join teams on teams.team = leasteconomy.team
join combinedovers on combinedovers.team = leasteconomy.team
order by "Average Economy"

-- 16) Who are the top 10 run scorers of the season?

select "Batter Name", "Runs Scored", "Strike Rate" from "ipl-batters" where "Runs Scored" > 175 order by "Runs Scored" desc limit 10

-- 17) What is the average strike rate of all right-handers vs left-handers?

with filter_batters as (
	select * from "ipl-batters"
	where "Batter Name" notnull
)

select "Batter Type" as "Batting Hand", round(avg("Strike Rate")::numeric,2) as "Avg. Strike Rate" 
from filter_batters group by "Batting Hand"

-- 18) Which batter has the best strike rate [Top-10] (min 50 balls faced)?

select "Batter Name", "Runs Scored", "Ball Taken", "Strike Rate" from "ipl-batters" where "Ball Taken" > 49 order by "Strike Rate" desc limit 10

-- 19) What is the average number of boundaries per batter?

with filter_batters as (
	select * from "ipl-batters"
	where "Batter Name" notnull
),

total_boundaries as (
	select sum("Fours") as fours, sum("Sixes") as sixes, count(*) as players
	from filter_batters
)

select 
	players as "Total Players",
	round((fours+sixes)/players::numeric,2) as "Average Boundaries Per Player" 
from total_boundaries

-- 20) Which batter scored the most runs through cover region [Top-10]?

select "Batter Name", "Cover" as "Runs at Cover Region" from "ipl-batters" order by "Runs at Cover Region" desc limit 10

-- 21) Which player had the most number of “Not Out” innings [Top-10]?

WITH all_batters AS (
    SELECT * FROM "rcb-batters" UNION ALL
    SELECT * FROM "csk-batters" UNION ALL
    SELECT * FROM "mi-batters" UNION ALL
    SELECT * FROM "kkr-batters" UNION ALL
    SELECT * FROM "srh-batters" UNION ALL
    SELECT * FROM "rr-batters" UNION ALL
    SELECT * FROM "pbks-batters" UNION ALL
    SELECT * FROM "gt-batters" UNION ALL
    SELECT * FROM "dc-batters" UNION ALL
    SELECT * FROM "lsg-batters"
)

select "Batter Name" as "Player Name", count(*) as "Not-Out Innings" from all_batters where "Status" = 'Not Out' group by "Player Name" order by "Not-Out Innings" desc limit 10

-- 22) Which batter hit the most sixes [Top-10]?

select "Batter Name", "Sixes" from "ipl-batters" order by "Sixes" desc limit 10

-- 23) Which batter has Scored 50+ with Highest Strike Rate?

WITH all_batters AS (
    SELECT * FROM "rcb-batters" UNION ALL
    SELECT * FROM "csk-batters" UNION ALL
    SELECT * FROM "mi-batters" UNION ALL
    SELECT * FROM "kkr-batters" UNION ALL
    SELECT * FROM "srh-batters" UNION ALL
    SELECT * FROM "rr-batters" UNION ALL
    SELECT * FROM "pbks-batters" UNION ALL
    SELECT * FROM "gt-batters" UNION ALL
    SELECT * FROM "dc-batters" UNION ALL
    SELECT * FROM "lsg-batters"
)

select "Batter Name", "Batter Type", "Runs Scored", round("Strike Rate"::numeric,2) as "Strike Rate" from all_batters where "Runs Scored" > 49 order by "Strike Rate" desc limit 10

-- 24) What’s the average contribution of top 3 batters per team?

with 
rcb_batters as ( select 'Royal Challengers Bengaluru' as team, sum(runs_scored) as top_3_total_runs from ( select "Batter Name" as "TOP-3 Contributors", sum("Runs Scored") as runs_scored from "rcb-batters" group by "Batter Name" order by runs_scored desc limit 3 ) as top3 ),
csk_batters as ( select 'Chennai Super Kings' as team, sum(runs_scored) as top_3_total_runs from ( select "Batter Name" as "TOP-3 Contributors", sum("Runs Scored") as runs_scored from "csk-batters" group by "Batter Name" order by runs_scored desc limit 3 ) as top3 ),
mi_batters as ( select 'Mumbai Indians' as team, sum(runs_scored) as top_3_total_runs from ( select "Batter Name" as "TOP-3 Contributors", sum("Runs Scored") as runs_scored from "mi-batters" group by "Batter Name" order by runs_scored desc limit 3 ) as top3 ),
kkr_batters as ( select 'Kolkata Knight Riders' as team, sum(runs_scored) as top_3_total_runs from ( select "Batter Name" as "TOP-3 Contributors", sum("Runs Scored") as runs_scored from "kkr-batters" group by "Batter Name" order by runs_scored desc limit 3 ) as top3 ),
srh_batters as ( select 'Sunrisers Hyderabad' as team, sum(runs_scored) as top_3_total_runs from ( select "Batter Name" as "TOP-3 Contributors", sum("Runs Scored") as runs_scored from "srh-batters" group by "Batter Name" order by runs_scored desc limit 3 ) as top3 ),
rr_batters as ( select 'Rajasthan Royals' as team, sum(runs_scored) as top_3_total_runs from ( select "Batter Name" as "TOP-3 Contributors", sum("Runs Scored") as runs_scored from "rr-batters" group by "Batter Name" order by runs_scored desc limit 3 ) as top3 ),
pbks_batters as ( select 'Punjab Kings' as team, sum(runs_scored) as top_3_total_runs from ( select "Batter Name" as "TOP-3 Contributors", sum("Runs Scored") as runs_scored from "pbks-batters" group by "Batter Name" order by runs_scored desc limit 3 ) as top3 ),
lsg_batters as ( select 'Lucknow Super Giants' as team, sum(runs_scored) as top_3_total_runs from ( select "Batter Name" as "TOP-3 Contributors", sum("Runs Scored") as runs_scored from "lsg-batters" group by "Batter Name" order by runs_scored desc limit 3 ) as top3 ),
gt_batters as ( select 'Gujarat Titans' as team, sum(runs_scored) as top_3_total_runs from ( select "Batter Name" as "TOP-3 Contributors", sum("Runs Scored") as runs_scored from "gt-batters" group by "Batter Name" order by runs_scored desc limit 3 ) as top3 ),
dc_batters as ( select 'Delhi Capitals' as team, sum(runs_scored) as top_3_total_runs from ( select "Batter Name" as "TOP-3 Contributors", sum("Runs Scored") as runs_scored from "dc-batters" group by "Batter Name" order by runs_scored desc limit 3 ) as top3 ),

rcb_total as ( select 'Royal Challengers Bengaluru' as team, sum("RCB Batting Score") as total_runs from rcb ),
csk_total as ( select 'Chennai Super Kings' as team, sum("CSK Batting Score") as total_runs from csk ),
mi_total as ( select 'Mumbai Indians' as team, sum("MI Batting Score") as total_runs from mi ),
kkr_total as ( select 'Kolkata Knight Riders' as team, sum("KKR Batting Score") as total_runs from kkr ),
srh_total as ( select 'Sunrisers Hyderabad' as team, sum("SRH Batting Score") as total_runs from srh ),
rr_total as ( select 'Rajasthan Royals' as team, sum("RR Batting Score") as total_runs from rr ),
pbks_total as ( select 'Punjab Kings' as team, sum("PBKS Batting Score") as total_runs from pbks ),
lsg_total as ( select 'Lucknow Super Giants' as team, sum("LSG Batting Score") as total_runs from lsg ),
gt_total as ( select 'Gujarat Titans' as team, sum("GT Batting Score") as total_runs from gt ),
dc_total as ( select 'Delhi Capitals' as team, sum("DC Batting Score") as total_runs from dc ),

combined as (
  select * from rcb_batters union all select * from csk_batters union all select * from mi_batters union all select * from kkr_batters union all select * from srh_batters union all select * from rr_batters union all select * from pbks_batters union all select * from lsg_batters union all select * from gt_batters union all select * from dc_batters
),

totals as (
  select * from rcb_total union all select * from csk_total union all select * from mi_total union all select * from kkr_total union all select * from srh_total union all select * from rr_total union all select * from pbks_total union all select * from lsg_total union all select * from gt_total union all select * from dc_total
)

select combined.team as "Team", top_3_total_runs as "Top-3 Total Runs", total_runs as "Team Total Runs", round((top_3_total_runs * 100.0 / total_runs)::numeric,2) as "Top-3 Contribution (%)" from combined join totals on combined.team = totals.team order by "Top-3 Contribution (%)" desc;

-- 25) How often did openers scored 50+ Runs Partnership together?

with all_partnerships as (
    select p.*, row_number() over (partition by p."Match Number", p."Home Team" order by 1) as rn
    from "ipl-partnerships" p where exists (
		select * from ipl i
		where i."Match Number" = p."Match Number"
		and i."Winning Team" not in ('Rain Interrupted (No Result)')
	)
),

only_opening_partnerships as (
    select * from all_partnerships
    where rn = 1
),

home_opening as (
    select "Home Team" as team, count(*) as "50+ Partnership Count"
    from only_opening_partnerships
    where "Home Team Partnership Score" > 49
    group by "Home Team"
),

away_opening as (
    select "Away Team" as team, count(*) as "50+ Partnership Count"
    from only_opening_partnerships
    where "Away Team Partnership Score" > 49
    group by "Away Team"
),

combined as (
    select * from home_opening
    union all
    select * from away_opening
)

select team as "Team", sum("50+ Partnership Count") as "(50+) Partnerships"
from combined
group by team
order by "(50+) Partnerships" desc

-- 26) Who are the Top-10 wicket-takers of the season?

select "Bowler Name", "Wickets Taken", "Economy" from "ipl-bowlers" order by "Wickets Taken" desc limit 10

-- 27) What is the average economy rate for pacers vs spinners?

with average_spin as (
	select 'Bowling' as common, avg("Economy") as econ_spin from "ipl-bowlers" where "Bowler Type" = 'Spinner'
),

average_pace as (
	select 'Bowling' as common, avg("Economy") as econ_pace from "ipl-bowlers" where "Bowler Type" = 'Pacer'
)

select
	round(econ_pace::numeric,2) as "Average Pacers Economy",
	round(average_spin.econ_spin::numeric,2) as "Average Spinners Economy"
from average_pace
join average_spin on average_pace.common = average_spin.common

-- 28) Who has the best bowling economy (min 20 overs bowled) [Top-10]?

select "Bowler Name", sum("Runs Conceeded") as "Runs Conceded", avg("Economy") as "Average Economy", sum("Overs Bowled") as "Overs Bowled" from "ipl-bowlers" where "Bowler Name" not in ('null') and "Overs Bowled" > 19 group by "Bowler Name" order by "Average Economy" limit 10

-- 29) Which bowler bowled the most dot balls [Top-10]?

select "Bowler Name", sum("Dots") as "Total Dot Balls" from "ipl-bowlers" 
group by "Bowler Name" 
order by "Total Dot Balls" desc limit 10

-- 30) Which bowler conceded the most Boundaries [Top-10]?

select 
	"Bowler Name", 
	sum("Sixes Conceded") as "Sixes Conceded",
	sum("Fours Conceded") as "Fours Conceded",
	sum("Sixes Conceded" + "Fours Conceded") as "Total Boundaries" 
from "ipl-bowlers"
where "Bowler Name" not in ('null')
group by "Bowler Name"
order by "Total Boundaries" desc limit 10

-- 31) List Top-10 bowlers conceeding the Most Runs (min 20 overs bowled)?

select "Bowler Name", sum("Runs Conceeded") as "Runs Conceded", sum("Overs Bowled") as "Overs Bowled" from "ipl-bowlers"
where "Bowler Name" not in ('null') and "Overs Bowled" > 19
group by "Bowler Name"
order by "Runs Conceded" desc limit 10

-- 32) Which bowler has the most [ Wickets to Balls Ratio } [Top-10] ?

select 
	"Bowler Name",
	sum("Balls Bowled") as "Balls Bowled",
	sum("Wickets Taken") as "Wickets Taken",
	round((sum("Balls Bowled")/sum("Wickets Taken"))::numeric,2) as "Wickets to Balls Ratio"
from "ipl-bowlers"
where "Wickets Taken" > 0 and "Balls Bowled" > 23
group by "Bowler Name"
order by "Wickets to Balls Ratio" limit 10

-- 33) What is the average number of wides per bowler?

select round(avg("Wides Given"),2) as "Average Wides Per Bowler" from "ipl-bowlers"

-- 34) Top-5 Bowlers with the best single-match performance?

WITH all_bowlers AS (
    SELECT 'rcb' as team, * FROM "rcb-bowlers" UNION ALL
    SELECT 'csk', * FROM "csk-bowlers" UNION ALL
    SELECT 'mi', * FROM "mi-bowlers" UNION ALL
    SELECT 'kkr', * FROM "kkr-bowlers" UNION ALL
    SELECT 'srh', * FROM "srh-bowlers" UNION ALL
    SELECT 'rr', * FROM "rr-bowlers" UNION ALL
    SELECT 'pbks', * FROM "pbks-bowlers" UNION ALL
    SELECT 'gt', * FROM "gt-bowlers" UNION ALL
    SELECT 'dc', * FROM "dc-bowlers" UNION ALL
    SELECT 'lsg', * FROM "lsg-bowlers"
)

select 
	upper(team) as "Team",
	"Opponent", "Bowler Hand",
	"Bowler Type", "Overs Bowled",
	"Wickets Taken", "Runs Conceeded" as "Runs Conceded",
	round("Economy"::numeric,2) as "Economy"
from all_bowlers
where "Bowler Name" not in ('null')
order by "Wickets Taken" desc limit 5

-- 35) Top-5 matches that had the highest combined score?

select
	"Match Number",
	"Home Team",
	"Away Team",
	sum("Home Team Score") as "Home Team Score",
	sum("Away Team Score") as "Away Team Score",
	sum("Home Team Score" + "Away Team Score") as "Combined Score",
	"Winning Team"
from ipl
where "Winning Team" not in ('Rain Interrupted (No Result)')
group by "Match Number", "Home Team", "Away Team", "Winning Team"
order by sum("Home Team Score" + "Away Team Score") desc limit 5

-- 36) Which match had the closest finish (least run/wicket margin) [Top-5]?

select
	"Match Number",
	"Home Team",
	"Away Team",
	"Home Team Score",
	"Away Team Score",
	"Winning Category",
	"Winning Margin",
	"Winning Team"
from ipl
where "Winning Team" not in ('Rain Interrupted (No Result)','Tie')
order by "Winning Margin" limit 5

-- 37) What was the average run rate per match across the season?

with f_ipl as (
	select * from ipl
	where "Home Team Run Rate" > 0
	and "Away Team Run Rate" > 0
)

select round(avg(nrr)::numeric,2) as "Average Run Rate" from (
	select avg("Home Team Run Rate") as nrr from ipl union all
	select avg("Away Team Run Rate") as nrr from ipl
) as avg_run_rate

-- 38) What’s the average number of wickets fallen in a match?

with f_ipl as (
	select * from ipl
	where "Home Team Wickets Fallen" > 0
	and "Away Team Wickets Fallen" > 0
)

select avg(wickets_fallen) as "Average Wickets Fallen Per Match" from (
	select avg("Home Team Wickets Fallen") as wickets_fallen from f_ipl union all
	select avg("Away Team Wickets Fallen") as wickets_fallen from f_ipl
) as avg_wickets_fallen_per_match

-- 39) How many matches were won chasing a target above 180+?

select count(*) as "Matches Won While Chasing Targets of 180+" from ipl
where "Winning Category" = 'Wickets' and ( "Home Team Score" >= 180 or "Away Team Score" >= 180 )

-- 40) What is the distribution of winning margins (by runs vs wickets)?

with defend as (select 'ipl' as common, count(*) as "Matches Won by Defending" from ipl where "Winning Category" = 'Runs'),
chase as (select 'ipl' as common, count(*) as "Matches Won by Chasing" from ipl where "Winning Category" = 'Wickets'),

combined as (
	select "Matches Won by Defending", chase."Matches Won by Chasing" from defend
	join chase on defend.common = chase.common
)

select * from combined
-- (Just to check how many matches had no result)
-- select * from ipl where "Winning Team" not in (select distinct("Home Team") from ipl)

-- 41) Which city saw the highest average score?

select "Venue", round(avg(venue_avg)::numeric,2) as "Venue Average Scores" from (
	select "Venue", avg("Home Team Score") as venue_avg from ipl group by "Venue" union all
	select "Venue", avg("Away Team Score") as venue_avg from ipl group by "Venue"
) as avg_venue_scores
group by "Venue"
order by "Venue Average Scores" desc

-- 42) Which batting pair had the most number of 50+ partnerships [Top-10]?

with pairs as (
	
	select 
		"Home Team", 
		"Away Team", 
		least("Home Team Player-1", "Home Team Player-2") as player_1,
		greatest("Home Team Player-1", "Home Team Player-2") as player_2,
		"Home Team Partnership Score" as p_score 
	from "ipl-partnerships"
	where "Home Team Partnership Score" >= 50

	union all

	select 
		"Home Team", 
		"Away Team", 
		least("Away Team Player-1", "Away Team Player-2") as player_1,
		greatest("Away Team Player-1", "Away Team Player-2") as player_2,
		"Away Team Partnership Score" as p_score
	from "ipl-partnerships"
	where "Away Team Partnership Score" >= 50

	
	order by p_score desc
	
)

select 
	player_1 as "Player-1",
	player_2 as "Player-2",
	count(*) as "Total 50+ Partnerships"
from pairs
group by player_1, player_2
order by "Total 50+ Partnerships" desc
limit 10

-- 43) What are the Top-5 Highest Partnership Score of the season?

with ipl_partnerships as (
	select * from "ipl-partnerships"
	where "Home Team Partnership Score" > 0
	and "Away Team Partnership Score" > 0
)

select 
	player_1 as "Player-1", 
	player_2 as "Player-2", 
	max(partnership_score) as "Partnership Score"
	from (
		select 
			"Home Team Player-1" as player_1, 
			"Home Team Player-2" as player_2, 
			max("Home Team Partnership Score") as partnership_score 
		from ipl_partnerships 
		group by player_1, player_2
		union all
		select 
			"Away Team Player-1" as player_1, 
			"Away Team Player-2" as player_2, 
			max("Away Team Partnership Score") as partnership_score 
		from ipl_partnerships
		group by player_1, player_2
) as max_partnership_score
group by player_1, player_2
order by "Partnership Score" desc
limit 10

-- 44) What is the average partnership per wicket per team?

with home_avg_partnership as (
	select
		"Home Team" as team,
		count(*) as wickets,
		sum("Home Team Partnership Score") as "Total Partnership Score"
	from "ipl-partnerships"
	group by team
),

away_avg_partnership as (
	select
		"Away Team" as team,
		count(*) as wickets,
		sum("Away Team Partnership Score") as "Total Partnership Score"
	from "ipl-partnerships"
	group by team
),

combined_avg_partnership as (
	select 
		home_avg_partnership.team as team,
		sum(home_avg_partnership.wickets+away_avg_partnership.wickets) as wickets,
		sum(home_avg_partnership."Total Partnership Score"+away_avg_partnership."Total Partnership Score") as partnership_runs
	from home_avg_partnership
	join away_avg_partnership on home_avg_partnership.team = away_avg_partnership.team
	group by home_avg_partnership.team

)

select 
	team as "Team",
	partnership_runs as "Partnership Runs",
	wickets as "Wickets Fallen",
	round((partnership_runs/wickets)::numeric,2) as "Average Partnership Score"
from combined_avg_partnership
order by "Average Partnership Score" desc

-- 45) What is the most productive batting position combo (e.g., 1 & 2, 3 & 4)?

with partnerships as (
	select * from "ipl-partnerships"
	where "Home Team Partnership Score" > 0
	and "Away Team Partnership Score" > 0
),

Unpivoted AS (
  SELECT 
    "Match Number",
    'Home' AS Team,
    "Home Team Player-1" AS Player,
    ROW_NUMBER() OVER (ORDER BY "Match Number") * 2 - 1 AS Appearance_Order
  FROM partnerships
  	UNION ALL
  SELECT
    "Match Number",
    'Home' AS Team,
    "Home Team Player-2" AS Player,
    ROW_NUMBER() OVER (ORDER BY "Match Number") * 2 AS Appearance_Order
  FROM partnerships
	UNION ALL
  SELECT
    "Match Number",
    'Away' AS Team,
    "Away Team Player-1" AS Player,
    ROW_NUMBER() OVER (ORDER BY "Match Number") * 2 - 1 AS Appearance_Order
  FROM partnerships
  UNION ALL
  SELECT
    "Match Number",
    'Away' AS Team,
    "Away Team Player-2" AS Player,
    ROW_NUMBER() OVER (ORDER BY "Match Number") * 2 AS Appearance_Order
  FROM partnerships
),

PlayerPositions AS (
  SELECT
    "Match Number",
    Team,
    Player,
    MIN(Appearance_Order) AS First_Appearance_Order
  FROM Unpivoted
  GROUP BY "Match Number", Team, Player
),

BattingOrder AS (
  SELECT
    "Match Number",
    Team,
    Player,
    ROW_NUMBER() OVER (PARTITION BY "Match Number", Team ORDER BY First_Appearance_Order) AS Batting_Position
  FROM PlayerPositions
	order by "Match Number"
),

PartnershipsWithPositions AS (
  SELECT
    p.*,
    h1.Batting_Position AS Home_Player_1_Position,
    h2.Batting_Position AS Home_Player_2_Position,
    a1.Batting_Position AS Away_Player_1_Position,
    a2.Batting_Position AS Away_Player_2_Position
  FROM "ipl-partnerships" p
  JOIN BattingOrder h1 ON p."Match Number" = h1."Match Number" AND h1.Team = 'Home' AND p."Home Team Player-1" = h1.Player
  JOIN BattingOrder h2 ON p."Match Number" = h2."Match Number" AND h2.Team = 'Home' AND p."Home Team Player-2" = h2.Player
  JOIN BattingOrder a1 ON p."Match Number" = a1."Match Number" AND a1.Team = 'Away' AND p."Away Team Player-1" = a1.Player
  JOIN BattingOrder a2 ON p."Match Number" = a2."Match Number" AND a2.Team = 'Away' AND p."Away Team Player-2" = a2.Player
),

PartnershipCombos AS (
  SELECT
    "Match Number",
    'Team' AS Team,
    CASE 
      WHEN Home_Player_1_Position < Home_Player_2_Position THEN CONCAT(Home_Player_1_Position, ' & ', Home_Player_2_Position)
      ELSE CONCAT(Home_Player_2_Position, ' & ', Home_Player_1_Position)
    END AS Batting_Combo,
    "Home Team Partnership Score" AS Partnership_Runs,
    "Home Team Partnership Balls Taken" AS Partnership_Balls
  FROM PartnershipsWithPositions
),

AwayPartnershipCombos AS (
  SELECT
    "Match Number",
    'Team' AS Team,
    CASE 
      WHEN Away_Player_1_Position < Away_Player_2_Position THEN CONCAT(Away_Player_1_Position, ' & ', Away_Player_2_Position)
      ELSE CONCAT(Away_Player_2_Position, ' & ', Away_Player_1_Position)
    END AS Batting_Combo,
    "Away Team Partnership Score" AS Partnership_Runs,
    "Away Team Partnership Balls Taken" AS Partnership_Balls
  FROM PartnershipsWithPositions
),

AllPartnershipCombos AS (
  SELECT * FROM PartnershipCombos
  UNION ALL
  SELECT * FROM AwayPartnershipCombos
)

SELECT
  Batting_Combo as "Pair",
  COUNT(*) AS "Number of Partnerships",
  SUM(Partnership_Runs) AS "Runs Scored",
  SUM(Partnership_Balls) AS "Deliveries Faced",
  round(AVG(Partnership_Runs)::numeric,2) AS "Average Runs",
  ROUND((SUM(Partnership_Runs) * 100.0 / NULLIF(SUM(Partnership_Balls), 0))::numeric, 2) AS "Average Strike Rate"
FROM AllPartnershipCombos
GROUP BY Team, Batting_Combo
ORDER BY "Runs Scored" DESC
LIMIT 5

-- 46) Which player has the highest average partnership runs in matches they were involved in [Top-10]?

with ipl_partnerships as (
    select * 
    from "ipl-partnerships"
    where "Home Team Partnership Score" > 0
      and "Away Team Partnership Score" > 0
),

all_players as (
    select distinct("Home Team Player-1") as player from ipl_partnerships union
    select distinct("Home Team Player-2") as player from ipl_partnerships union
    select distinct("Away Team Player-1") as player from ipl_partnerships union
    select distinct("Away Team Player-2") as player from ipl_partnerships
),

player_partnership_avg as (
    select 
        p.*,
        ap.player as involved_player,
		CASE 
            WHEN ap.player = p."Home Team Player-1" OR ap.player = p."Home Team Player-2"
                THEN p."Home Team Partnership Score"
            ELSE p."Away Team Partnership Score"
        END AS partnership_score
    from ipl_partnerships p
    join all_players ap
        on ap.player = p."Home Team Player-1"
        or ap.player = p."Home Team Player-2"
        or ap.player = p."Away Team Player-1"
        or ap.player = p."Away Team Player-2"
)

select 
    involved_player as "Player",
    count(*) as "Number Of Partnerships",
	round(avg(partnership_score)::numeric,2) as "Average Runs Contributed"
from player_partnership_avg
group by involved_player
having count(*) > 10
order by "Average Runs Contributed" desc
limit 10

-- 47) Which team scored the most runs in the powerplay along with average?

with f_overwise as (
	SELECT *
	FROM "ipl-overwise" o
	WHERE "Over Number" = 6
	  AND EXISTS (
		SELECT 1
		FROM "ipl" i
		WHERE i."Home Team" = o."Home Team"
		  AND i."Away Team" = o."Away Team"
		  AND i."Winning Team" NOT IN ('Rain Interrupted (No Result)')
		  AND i."Winning Team" notnull
	  )
),

home_powerplay as (
	select 
		"Home Team" as team,
		count(*) as appearances,
		sum("Home Team Score") as score
	from f_overwise
	group by team
),

away_powerplay as (
	select 
		"Away Team" as team,
		count(*) as appearances,
		sum("Away Team Score") as score
	from f_overwise
	group by team
),

combined_powerplay as (
	SELECT 
		team, 
		SUM(appearances) AS total_appearances,
		SUM(score) AS total_score
	FROM (
		SELECT * FROM home_powerplay
		UNION ALL
		SELECT * FROM away_powerplay
	) AS combined
	GROUP BY team
)

select
	team as "Team",
	total_score as "Total Runs in Powerplay",
	round((total_score/total_appearances)::numeric,2) as "Average Runs in Powerplay"
from combined_powerplay
order by "Average Runs in Powerplay" desc

-- 48) Which team had the best 19th over stats across the season?

with f_overwise as (
	select * from "ipl-overwise" o
	where "Over Number" = 19
	and ("Home Team Runs Scored" >= 0 or "Away Team Runs Scored" >= 0 )
	and exists (
		select 1 from "ipl" i
		where i."Home Team" = o."Home Team"
		and i."Away Team" = o."Away Team"
		and i."Winning Team" not in ('-','_','Rain Interrupted (No Result)')
	)
),

home_19th_over as (
	select 
		"Home Team" as team,
		count(*) as matches,
		sum("Home Team Runs Scored") as runs_19th_over
	from f_overwise
	group by team
),

away_19th_over as (
	select
		"Away Team" as team,
		count(*) as matches,
		sum("Away Team Runs Scored") as runs_19th_over
	from f_overwise
	group by team
),

combined_19th_over as (
	select team, sum(runs_19th_over) as runs_in_19th_over, sum(matches) as matches from (
		select team, sum(matches) as matches, sum(runs_19th_over) as runs_19th_over from home_19th_over group by team union all
		select team, sum(matches) as matches, sum(runs_19th_over) as runs_19th_over from away_19th_over group by team
	) as runs_in_19th
	group by team
)

select
	team as "Team",
	matches as "Matches Played Inclusive Of 19th Over",
	runs_in_19th_over as "Total Runs Scored in 19th Over",
	round((runs_in_19th_over/matches)::numeric,2) as "Average Runs in 19th Over"
from combined_19th_over
order by "Average Runs in 19th Over" desc

-- 49) Which team scored the most runs in Death Overs (16–20)?

with f_overwise as (
	select * from "ipl-overwise" o
	where "Over Number" >= 16
	and exists (
		select 1
		from "ipl" i
		where i."Home Team" = o."Home Team"
		and i."Away Team" = o."Away Team"
		and i."Winning Team" not in ('Rain Interrupted (No Result)')
		and i."Winning Team" notnull
	)
),

home_deathovers as (
	select
		"Home Team" as team,
		count(*) as overs,
		count(distinct "Match Number") as matches,
		sum("Home Team Runs Scored") as ts
	from f_overwise
	group by team
	order by ts desc
),

away_deathovers as (
	select
		"Away Team" as team,
		count(*) as overs,
		count(distinct "Match Number") as matches,
		sum("Away Team Runs Scored") as ts
	from f_overwise
	group by team
	order by ts desc
),

combined_deathovers as (
	select team, sum(matches) as matches, sum(runs_in_death) as runs_in_death, sum(overs) as overs from (
		select team, sum(matches) as matches, sum(ts) as runs_in_death, sum(overs) as overs from home_deathovers group by team union all
		select team, sum(matches) as matches, sum(ts) as runs_in_death, sum(overs) as overs from away_deathovers group by team
	) as deathover_runs
	group by team
)

select
	team as "Team",
	overs as "Total Overs Played",
	matches as "Total Matches Played inclusive of (16-20 Overs)",
	runs_in_death as "Total Death Over Runs Scored",
	round((runs_in_death/matches)::numeric,2) as "Average Runs in Death Overs",
	round((runs_in_death/overs)::numeric,2) as "Net Run-Rate in Death Overs"
from combined_deathovers
order by "Average Runs in Death Overs" desc

-- 50) What is the average runs scored per over across teams?

with f_overwise as (
	select * from "ipl-overwise" o
	where ( "Home Team Runs Scored" > 0 or "Away Team Runs Scored" > 0 )
	and exists (
		select * from "ipl" i
		where i."Home Team" = o."Home Team"
		and i."Away Team" = o."Away Team"
		and i."Winning Team" not in ('-','_','Rain Interrupted (No Result)')
	)
),

home_perover as (
	select
		"Home Team" as team,
		count(*) as overs,
		sum("Home Team Runs Scored") as runs_scored
	from f_overwise
	group by team
),

away_perover as (
	select
		"Away Team" as team,
		count(*) as overs,
		sum("Away Team Runs Scored") as runs_scored
	from f_overwise
	group by team
),

combined_perover as (
	select team, sum(overs) as overs, sum(runs_scored) as runs_scored from (
		select team, sum(overs) as overs, sum(runs_scored) as runs_scored from home_perover group by team union all
		select team, sum(overs) as overs, sum(runs_scored) as runs_scored from away_perover group by team
	) as all_overs_runs
	group by team
)

select
	team as "Team",
	overs as "Total Overs Played",
	runs_scored as "Total Runs Scored Throughout Tournament",
	round((runs_scored/overs)::numeric,2) as "Average Runs Per Over"
from combined_perover
order by "Average Runs Per Over" desc

-- 51) How many overs went for more than 20 runs?

select count(*) as "Number Of Overs Conceding Over 20+ Runs" 
from "ipl-overwise"
where "Home Team Runs Scored" > 20
or "Away Team Runs Scored" > 20

-- 52) How much did Impact players contribute Throughout Tournament and Team-Wise?

with f_ipl as (
	select * from ipl
	where "Winning Team" not in ('-','_','Rain Interrupted (No Result)')
),

all_teams_info as (
	select * from rcb union all
	select * from csk union all
	select * from kkr union all
	select * from rr union all
	select * from srh union all
	select * from lsg union all
	select * from dc union all
	select * from mi union all
	select * from pbks union all
	select * from gt
),

all_batters as (
	select 'Royal Challengers Bengaluru' as team, * from "rcb-batters" union all
	select 'Chennai Super Kings' as team, * from "csk-batters" union all
	select 'Kolkata Knight Riders' as team, * from "kkr-batters" union all
	select 'Rajasthan Royals' as team, * from "rr-batters" union all
	select 'Sunrisers Hyderabad' as team, * from "srh-batters" union all
	select 'Mumbai Indians' as team, * from "mi-batters" union all
	select 'Punjab Kings' as team, * from "pbks-batters" union all
	select 'Gujarat Titans' as team, * from "gt-batters" union all
	select 'Delhi Capitals' as team, * from "dc-batters" union all
	select 'Lucknow Super Giants' as team, * from "lsg-batters"
),

all_bowlers as (
	select 'Royal Challengers Bengaluru' as team, * from "rcb-bowlers" union all
	select 'Chennai Super Kings' as team, * from "csk-bowlers" union all
	select 'Kolkata Knight Riders' as team, * from "kkr-bowlers" union all
	select 'Rajasthan Royals' as team, * from "rr-bowlers" union all
	select 'Sunrisers Hyderabad' as team, * from "srh-bowlers" union all
	select 'Mumbai Indians' as team, * from "mi-bowlers" union all
	select 'Punjab Kings' as team, * from "pbks-bowlers" union all
	select 'Gujarat Titans' as team, * from "gt-bowlers" union all
	select 'Delhi Capitals' as team, * from "dc-bowlers" union all
	select 'Lucknow Super Giants' as team, * from "lsg-bowlers"
),

impact_players as (
	select "Match Number", "Team", "Opponent", "RCB Impact Player" as player from all_teams_info
),

batunit as (
		select team, player, sum(runs_scored) as total_runs, count(*) as batted from (
			select team, player, bat."Runs Scored" as runs_scored from impact_players i
			join all_batters bat 
			  on bat."Match Number" = i."Match Number"
			 and player = bat."Batter Name"
			 and i."Team" = bat.team
		) as combined
		group by team, player
		order by total_runs desc
),

ballunit as (
	select team, player, sum(wickets_taken) as wickets_taken, count(*) as bowled from (
			select team, player, ball."Wickets Taken" as wickets_taken from impact_players i
			join all_bowlers ball
			  on ball."Match Number" = i."Match Number"
			 and player = ball."Bowler Name"
			 and i."Team" = ball.team
		) as combined
		group by team, player
		order by wickets_taken desc
)

select 
	total_runs as "Total Runs Scored By Impact Batters",
	batted as "Number of Impact Player Batting Innings",
	round(total_runs/batted::numeric,2) as "Average Batting Score By Impact Batter"
	from (
		select sum(total_runs) as total_runs, sum(batted) as batted from batunit
	) as combined_batting_impact

select 
	wickets_taken as "Total Wickets Taken By Impact Bowlers",
	bowled as "Total Bowling Innings",
	round((wickets_taken/bowled)::numeric,2) as "Average Wickets Taken By Impact Bowler"
	from (
		select sum(wickets_taken) as wickets_taken, sum(bowled) as bowled from ballunit
	) as combined_bowling_impact
	
select
	team as "Team",
	sum(total_runs) as "Total Runs",
	sum(batted) as "Total Innings with Impact Player",
	round((sum(total_runs)/sum(batted))::numeric,2) as "Average Runs Scored by Impact Players per Match"
from batunit
group by team
order by "Total Runs" desc

select
	team as "Team",
	sum(bowled) as "Total Innings with Impact Player",
	sum(wickets_taken) as "Total Wickets",
	round((sum(wickets_taken)::numeric/sum(bowled)),2) as "Average Wickets Taken by Impact Players per Match"
from ballunit
group by team
order by "Total Wickets" desc
	
-- 53) How much did Substituted players contribute Throughout Tournament and Team-Wise?

with f_ipl as (
	select * from ipl
	where "Winning Team" not in ('-','_','Rain Interrupted (No Result)')
),

all_teams_info as (
	select * from rcb union all
	select * from csk union all
	select * from kkr union all
	select * from rr union all
	select * from srh union all
	select * from lsg union all
	select * from dc union all
	select * from mi union all
	select * from pbks union all
	select * from gt
),

all_batters as (
	select 'Royal Challengers Bengaluru' as team, * from "rcb-batters" union all
	select 'Chennai Super Kings' as team, * from "csk-batters" union all
	select 'Kolkata Knight Riders' as team, * from "kkr-batters" union all
	select 'Rajasthan Royals' as team, * from "rr-batters" union all
	select 'Sunrisers Hyderabad' as team, * from "srh-batters" union all
	select 'Mumbai Indians' as team, * from "mi-batters" union all
	select 'Punjab Kings' as team, * from "pbks-batters" union all
	select 'Gujarat Titans' as team, * from "gt-batters" union all
	select 'Delhi Capitals' as team, * from "dc-batters" union all
	select 'Lucknow Super Giants' as team, * from "lsg-batters"
),

all_bowlers as (
	select 'Royal Challengers Bengaluru' as team, * from "rcb-bowlers" union all
	select 'Chennai Super Kings' as team, * from "csk-bowlers" union all
	select 'Kolkata Knight Riders' as team, * from "kkr-bowlers" union all
	select 'Rajasthan Royals' as team, * from "rr-bowlers" union all
	select 'Sunrisers Hyderabad' as team, * from "srh-bowlers" union all
	select 'Mumbai Indians' as team, * from "mi-bowlers" union all
	select 'Punjab Kings' as team, * from "pbks-bowlers" union all
	select 'Gujarat Titans' as team, * from "gt-bowlers" union all
	select 'Delhi Capitals' as team, * from "dc-bowlers" union all
	select 'Lucknow Super Giants' as team, * from "lsg-bowlers"
),

substituted_players as (
	select "Match Number", "Team", "Opponent", "RCB Substituted Player" as player from all_teams_info
),

batunit as (
		select team, player, sum(runs_scored) as total_runs, count(*) as batted from (
			select team, player, bat."Runs Scored" as runs_scored from substituted_players i
			join all_batters bat 
			  on bat."Match Number" = i."Match Number"
			 and player = bat."Batter Name"
			 and i."Team" = bat.team
		) as combined
		group by team, player
		order by total_runs desc
),

ballunit as (
	select team, player, sum(wickets_taken) as wickets_taken, count(*) as bowled from (
			select team, player, ball."Wickets Taken" as wickets_taken from substituted_players i
			join all_bowlers ball
			  on ball."Match Number" = i."Match Number"
			 and player = ball."Bowler Name"
			 and i."Team" = ball.team
		) as combined
		group by team, player
		order by wickets_taken desc
)

select 
	total_runs as "Total Runs Scored By Substituted Batters",
	batted as "Total Batting Innings",
	round(total_runs/batted::numeric,2) as "Average Batting Score By Substituted Batter"
	from (
		select sum(total_runs) as total_runs, sum(batted) as batted from batunit
	) as combined_batting_impact

select 
	wickets_taken as "Total Wickets Taken By Substituted Bowlers",
	bowled as "Total Bowling Innings",
	round((wickets_taken/bowled)::numeric,2) as "Average Wickets Taken By Substituted Bowler"
	from (
		select sum(wickets_taken) as wickets_taken, sum(bowled) as bowled from ballunit
	) as combined_bowling_impact

select
	team as "Team",
	sum(total_runs) as "Total Runs",
	sum(batted) as "Total Innings With Substitution",
	round((sum(total_runs)/sum(batted))::numeric,2) as "Average Runs Scored by Substituted Players per Match"
from batunit
group by team
order by "Total Runs" desc

select
	team as "Team",
	sum(wickets_taken) as "Total Wickets",
	sum(bowled) as "Total Innings With Substitution",
	round((sum(wickets_taken)::numeric/sum(bowled)),2) as "Average Wickets Taken by Substituted Players per Match"
from ballunit
group by team
order by "Total Wickets" desc

-- 54) What is the win percentage in matches where the Impact Player contributed?

with total_matches as (
	select "Home Team" as team, count(*) as matches from ipl
	where "Winning Team" not in ('Tie','Rain Interrupted (No Result)','-','_')
	group by team
),

won_by_impact as (
	select team, sum(won) as won from (
		select "Home Team" as team, count(*) as won from ipl
		where "Home Team" = "Winning Team"
		and "Home Team Impact Player" != 'null'
		group by team
			union all
		select "Away Team" as team, count(*) as won from ipl
		where "Away Team" = "Winning Team"
		and "Away Team Impact Player" != 'null'
		group by team
	) as impact_wins
	group by team
)

select
	sum(matches) as "Total Matches With Impact Players",
	sum(won_by_impact.won) as "Total Won with Impact Substitution",
	round((sum(won_by_impact.won)*100.0/sum(matches))::numeric,2) as "Winning Percentage with Impact Player"
from total_matches
join won_by_impact on won_by_impact.team = total_matches.team

-- 55) What is the win percentage of each captain?

with f_ipl as (
	select * from ipl
	where "Winning Team" not in ('-','_','Rain Interrupted (No Result)','Tie')
),

capwins as (
	
	select player, sum(wins) as wins, sum(loses) as loses from (
		select
			"Home Team Captain" as player,
			sum(case when "Home Team" = "Winning Team" then 1 else 0 end) as wins,
			sum(case when "Home Team" != "Winning Team" then 1 else 0 end) as loses
		from f_ipl
		group by player

		union all

		select
			"Away Team Captain" as player,
			sum(case when "Away Team" = "Winning Team" then 1 else 0 end) as wins,
			sum(case when "Away Team" != "Winning Team" then 1 else 0 end) as loses
		from f_ipl
		group by player
	) as combined
	group by player
	
)

select
	player as "Captain",
	sum(wins)+sum(loses) as "Total Matches as captain",
	sum(wins) as "Wins",
	sum(loses) as "Loses",
	round((sum(wins)*100/(sum(wins)+sum(loses)))::numeric,2) as "Win Percentage"
from capwins
group by player
order by "Win Percentage" desc

-- 56) Which captain made the most impact choices (most substituted players)?

select player, sum(subs_done) as "Impact-Substitutions Done", sum(matches) as "Total Matches" from (
	select
		"Home Team Captain" as player,
		sum (case when "Home Team Impact Player" notnull then 1 else 0 end) as subs_done,
		sum (case when "Winning Team" notnull then 1 else 0 end) as matches
	from ipl
	group by player

	union all

	select
		"Away Team Captain" as player,
		sum (case when "Away Team Impact Player" notnull then 1 else 0 end) as subs_done,
		sum (case when "Winning Team" notnull then 1 else 0 end) as matches
	from ipl
	group by player
) as combined

where player notnull
group by player
order by "Impact-Substitutions Done" desc

-- 57) What is the result of every head-to-head between specific team pairs?

-- CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT * FROM crosstab(
	
  $$
	  SELECT team_a, team_b, COUNT(*) AS wins FROM (
		SELECT "Home Team" AS team_a, "Away Team" AS team_b, "Winning Team" FROM ipl
		WHERE "Winning Team" NOT IN ('-', '_', 'Rain Interrupted (No Result)', 'Tie')
			UNION ALL
		SELECT "Away Team" AS team_a, "Home Team" AS team_b, "Winning Team" FROM ipl
		WHERE "Winning Team" NOT IN ('-', '_', 'Rain Interrupted (No Result)', 'Tie')
	  ) AS all_matches

	  WHERE team_a = "Winning Team"
	  GROUP BY team_a, team_b
	  ORDER BY team_a, team_b
  $$,

  $$ SELECT DISTINCT "Home Team" FROM ipl ORDER BY 1 $$
	
) AS head_to_head_matrix (
  "Team" TEXT,
  "Chennai Super Kings" INT, "Delhi Capitals" INT, "Gujarat Titans" INT, "Kolkata Knight Riders" INT, "Lucknow Super Giants" INT,
  "Mumbai Indians" INT, "Punjab Kings" INT, "Rajasthan Royals" INT, "Royal Challengers Bengaluru" INT, "Sunrisers Hyderabad" INT
)

-- 58) Which team had the best record in away matches?

select
	team as "Team",
	sum(total_matches) as "Total Matches",
	sum(matches_won) as "Matches Won Away From Home",
	round((sum(matches_won)*100/sum(total_matches))::numeric,2) as "Win Percentage At Away Venues"
	from (
	select
		"Away Team" as team,
		count(*) filter (where "Winning Team" = "Away Team") as matches_won,
		count(*) filter (where "Winning Team" notnull) as total_matches
	from ipl
	where "Winning Team" not in ('Rain Interrupted (No Result)','Tie')
	group by team
) as away_teamwins
group by "Team"
order by "Win Percentage At Away Venues" desc

-- 59) What’s the Team's Win-Loss Record At their Home-Ground?

select
	team as "Team",
	venue as "Venue",
	sum(wins)+sum(loses) as "Total Matches Played At This Venue",
	sum(wins) as "Wins",
	sum(loses) as "Loses",
	round((sum(wins)*100/(sum(wins)+sum(loses)))::numeric,2) as "Win Percentage At This Venue" from (
	select
		"Home Team" as team,
		"Venue" as venue,
		count(*) filter (where "Winning Team" = "Home Team") as wins,
		count(*) filter (where "Winning Team" != "Home Team") as loses
	from ipl
	where "Winning Team" not in ('Rain Interrupted (No Result)','Tie')
	group by team, venue
	
	union all
	
	select
		"Away Team" as team,
		"Venue" as venue,
		count(*) filter (where "Winning Team" = "Away Team") as wins,
		count(*) filter (where "Winning Team" != "Away Team") as loses
	from ipl
	where "Winning Team" not in ('Rain Interrupted (No Result)','Tie')
	group by team, venue
	
) as combined
group by team, venue
having sum(wins)+sum(loses) > 3
order by "Win Percentage At This Venue" desc

-- 60) Compare each team’s performance across the season by total Runs scored and Wickets taken.

select 
	team as "Team",
	sum(matches_played) as "Total Matches Played",
	sum(total_runs) as "Total Runs Scored Throughout The Season",
	sum(wickets_taken) as "Total Wickets Taken Throughout The Season",
	round((sum(total_runs)/sum(matches_played))::numeric,2) as "Average Runs Per Match",
	round((sum(wickets_taken)/sum(matches_played))::numeric,2) as "Average Wickets Taken Per Match"
from (
	select 
		"Home Team" as team,
		count(*) as matches_played,
		sum("Home Team Score") as total_runs,
		sum("Away Team Wickets Fallen") as wickets_taken
	from ipl
	where "Winning Team" not in ('Rain Interrupted (No Result)','Tie')
	group by team
	
	union all
	
	select
		"Away Team" as team,
		count(*) as matches_played,
		sum("Away Team Score") as total_runs,
		sum("Home Team Wickets Fallen") as wickets_taken
	from ipl
	where "Winning Team" not in ('Rain Interrupted (No Result)','Tie')
	group by team
) as combined
group by team
order by "Average Runs Per Match" desc, "Average Wickets Taken Per Match" desc

-- 61) What’s the average contribution of top 5 players (bat + bowl) per team?

with valid_ipl as (
	select * from ipl
	where "Winning Team" not in ('Rain Interrupted (No Result)','Tie')
),

all_batters as (
	select team, "Batter Name" as player, sum("Runs Scored") as runs from (
		select 'rcb' as team, * from "rcb-batters" union all
		select 'csk' as team, * from "csk-batters" union all
		select 'kkr' as team, * from "kkr-batters" union all
		select 'rr' as team, * from "rr-batters" union all
		select 'srh' as team, * from "srh-batters" union all
		select 'pbks' as team, * from "pbks-batters" union all
		select 'gt' as team, * from "gt-batters" union all
		select 'lsg' as team, * from "lsg-batters" union all
		select 'dc' as team, * from "dc-batters" union all
		select 'mi' as team, * from "mi-batters"
	) bat
	group by team, player
),

all_bowlers as (
	select team, "Bowler Name" as player, sum("Wickets Taken") as wickets from (
		select 'rcb' as team, * from "rcb-bowlers" union all
		select 'csk' as team, * from "csk-bowlers" union all
		select 'kkr' as team, * from "kkr-bowlers" union all
		select 'rr' as team, * from "rr-bowlers" union all
		select 'srh' as team, * from "srh-bowlers" union all
		select 'pbks' as team, * from "pbks-bowlers" union all
		select 'gt' as team, * from "gt-bowlers" union all
		select 'lsg' as team, * from "lsg-bowlers" union all
		select 'dc' as team, * from "dc-bowlers" union all
		select 'mi' as team, * from "mi-bowlers"
	) ball
	group by team, player
),

combined_runs as ( select team, sum(runs) as runs from all_batters group by team ),

combined_wickets as ( select team, sum(wickets) as wickets from all_bowlers group by team ),

combined_total as (
	select b.team as team, sum(b.runs) as runs, sum(w.wickets) as wickets
	from combined_runs b
	left join combined_wickets w on b.team = w.team
	group by b.team
),

ranked_batters as (
	select team, sum(runs) as runs from (
		select team, player, runs, row_number() over (partition by team order by runs desc) as rn
		from all_batters 
	) bat
	where rn<6
	group by team
),

ranked_bowlers as (
	select team, sum(wickets) as wickets from (
		select team, player, wickets, row_number() over (partition by team order by wickets desc) as rn
		from all_bowlers
	) ball
	where rn<6
	group by team
)

select
	upper(c.team) as "Team",
	sum(c.runs) as "Total Runs",
	sum(c.wickets) as "Total Wickets",
	sum(bat.runs) as "Top-5 Runs Contribution",
	sum(ball.wickets) as "Top-5 Wickets Contribution",
	round((sum(bat.runs)*100/sum(c.runs))::numeric,2) as "% Contributed by Top-5 in Batting",
	round((sum(ball.wickets)*100/sum(c.wickets))::numeric,2) as "% Contributed by Top-5 in Bowling"
from combined_total c
left join ranked_batters bat on bat.team = c.team
left join ranked_bowlers ball on ball.team = c.team
group by c.team
order by "% Contributed by Top-5 in Batting" desc, "% Contributed by Top-5 in Bowling" desc

-- 62) Which team had most players with 30+ runs or 2+ wickets in a match?

with valid_ipl as (
	select * from ipl
	where "Winning Team" not in ('Rain Interrupted (No Result)','Tie')
),

all_bat_30runs as (
	select team, occurrence from (
		select 'rcb' as team, count(*) filter (where "Runs Scored" > 29) as occurrence from "rcb-batters"
			union all
		select 'csk', count(*) filter (where "Runs Scored" > 29) from "csk-batters" union all
		select 'kkr', count(*) filter (where "Runs Scored" > 29) from "kkr-batters" union all
		select 'pbks', count(*) filter (where "Runs Scored" > 29) from "pbks-batters" union all
		select 'rr', count(*) filter (where "Runs Scored" > 29) from "rr-batters" union all
		select 'gt', count(*) filter (where "Runs Scored" > 29) from "gt-batters" union all
		select 'lsg', count(*) filter (where "Runs Scored" > 29) from "lsg-batters" union all
		select 'mi', count(*) filter (where "Runs Scored" > 29) from "mi-batters" union all
		select 'dc', count(*) filter (where "Runs Scored" > 29) from "dc-batters" union all
		select 'srh', count(*) filter (where "Runs Scored" > 29) from "srh-batters"
	) bat30runs
),

all_ball_2wickets as (
	select team, occurrence from (
		select 'rcb' as team, count(*) filter (where "Wickets Taken" > 1) as occurrence from "rcb-bowlers"
			union all
		select 'csk', count(*) filter (where "Wickets Taken" > 1) from "csk-bowlers" union all
		select 'kkr', count(*) filter (where "Wickets Taken" > 1) from "kkr-bowlers" union all
		select 'pbks', count(*) filter (where "Wickets Taken" > 1) from "pbks-bowlers" union all
		select 'rr', count(*) filter (where "Wickets Taken" > 1) from "rr-bowlers" union all
		select 'gt', count(*) filter (where "Wickets Taken" > 1) from "gt-bowlers" union all
		select 'lsg', count(*) filter (where "Wickets Taken" > 1) from "lsg-bowlers" union all
		select 'mi', count(*) filter (where "Wickets Taken" > 1) from "mi-bowlers" union all
		select 'dc', count(*) filter (where "Wickets Taken" > 1) from "dc-bowlers" union all
		select 'srh', count(*) filter (where "Wickets Taken" > 1) from "srh-bowlers"
	) bat30runs
)

select
	upper(bat.team) as "Team",
	bat.occurrence "Batters with 30+ Runs in a Match",
	ball.occurrence as "Bowlers with 2+ Wickets in a Match"
from all_bat_30runs bat
left join all_ball_2wickets ball on bat.team = ball.team
order by "Batters with 30+ Runs in a Match" desc, "Bowlers with 2+ Wickets in a Match" desc

-- 63) Which team relied on fewer players to win (i.e., low player spread but high result)?

with valid_ipl as (
	select * from ipl
	where "Winning Team" not in ('Rain Interrupted (No Result)','Tie')
),

distinct_batters as (
	select team, players from (
		select 'Royal Challengers Bengaluru' as team, count(distinct "Batter Name") as players from "rcb-batters" union
		select 'Kolkata Knight Riders', count(distinct "Batter Name") from "kkr-batters" union
		select 'Mumbai Indians', count(distinct "Batter Name") from "mi-batters" union
		select 'Rajasthan Royals', count(distinct "Batter Name") from "rr-batters" union
		select 'Gujarat Titans', count(distinct "Batter Name") from "gt-batters" union
		select 'Delhi Capitals', count(distinct "Batter Name") from "dc-batters" union
		select 'Sunrisers Hyderabad', count(distinct "Batter Name") from "srh-batters" union
		select 'Lucknow Super Giants', count(distinct "Batter Name") from "lsg-batters" union
		select 'Chennai Super Kings', count(distinct "Batter Name") from "csk-batters" union
		select 'Punjab Kings', count(distinct "Batter Name") from "pbks-batters"
	) bat
),

distinct_bowlers as (
	select team, players from (
		select 'Royal Challengers Bengaluru' as team, count(distinct "Bowler Name") as players from "rcb-bowlers" union
		select 'Chennai Super Kings', count(distinct "Bowler Name") from "csk-bowlers" union
		select 'Kolkata Knight Riders', count(distinct "Bowler Name") from "kkr-bowlers" union
		select 'Mumbai Indians', count(distinct "Bowler Name") from "mi-bowlers" union
		select 'Rajasthan Royals', count(distinct "Bowler Name") from "rr-bowlers" union
		select 'Gujarat Titans', count(distinct "Bowler Name") from "gt-bowlers" union
		select 'Delhi Capitals', count(distinct "Bowler Name") from "dc-bowlers" union
		select 'Sunrisers Hyderabad' as team, count(distinct "Bowler Name") from "srh-bowlers" union
		select 'Lucknow Super Giants', count(distinct "Bowler Name") from "lsg-bowlers" union
		select 'Punjab Kings', count(distinct "Bowler Name") from "pbks-bowlers"
	) ball
),

distinct_players as (
	select bat.team, sum(bat.players+ball.players) as players from distinct_batters bat
	join distinct_bowlers ball on bat.team = ball.team
	group by bat.team
),

wins as (
	select team, sum(wins) as wins from (
		select "Home Team" as team, count(*) filter (where "Winning Team" = "Home Team") as wins from valid_ipl group by team union all
		select "Away Team" as team, count(*) filter (where "Winning Team" = "Away Team") as wins from valid_ipl group by team
	) winners
	group by team
)

select
	p.team as "Team",
	p.players as "Total Players Played",
	w.wins as "Total Wins"
from distinct_players p
join wins w on w.team = p.team
order by "Total Players Played", "Total Wins" desc

-- 68) Which batter scored the most via "Third Man" region [Top-10]?
select "Batter Name", "Third Man" as "Runs Scored at Third Man" from "ipl-batters" order by "Third Man" desc limit 10

-- 69) How many times did a player get out within 5 balls faced?

with valid_ipl as (
	select * from ipl
	where "Winning Team" not in ('Rain Interrupted (No Result)','Tie')
),

less_than_5balls as (
	select sum(times) as times from (
		select count(*) filter (where "Ball Taken" < 6 and "Status" not in ('Not Out')) as times from "rcb-batters" where exists (select 1 from valid_ipl) union all
		select count(*) filter (where "Ball Taken" < 6 and "Status" not in ('Not Out')) from "csk-batters" where exists (select 1 from valid_ipl) union all
		select count(*) filter (where "Ball Taken" < 6 and "Status" not in ('Not Out')) from "kkr-batters" where exists (select 1 from valid_ipl) union all
		select count(*) filter (where "Ball Taken" < 6 and "Status" not in ('Not Out')) from "mi-batters" where exists (select 1 from valid_ipl) union all
		select count(*) filter (where "Ball Taken" < 6 and "Status" not in ('Not Out')) from "srh-batters" where exists (select 1 from valid_ipl) union all
		select count(*) filter (where "Ball Taken" < 6 and "Status" not in ('Not Out')) from "pbks-batters" where exists (select 1 from valid_ipl) union all
		select count(*) filter (where "Ball Taken" < 6 and "Status" not in ('Not Out')) from "dc-batters" where exists (select 1 from valid_ipl) union all
		select count(*) filter (where "Ball Taken" < 6 and "Status" not in ('Not Out')) from "gt-batters" where exists (select 1 from valid_ipl) union all
		select count(*) filter (where "Ball Taken" < 6 and "Status" not in ('Not Out')) from "lsg-batters" where exists (select 1 from valid_ipl) union all
		select count(*) filter (where "Ball Taken" < 6 and "Status" not in ('Not Out')) from "rr-batters" where exists (select 1 from valid_ipl)
	) as combined
)

select times as "Number of Times Batters Got Out Facing Atmost 5-Balls" from less_than_5balls

-- 66) How many matches saw less than 6-sixes from a team?

with valid_ipl as (
	select match_number, team, opponent, winning_team from (
		select "Match Number" as match_number, "Team" as team, "Opponent" as opponent, "Winning Team" as winning_team from rcb union all
		select "Match Number", "Team", "Opponent", "Winning Team" from csk union all
		select "Match Number", "Team", "Opponent", "Winning Team" from kkr union all
		select "Match Number", "Team", "Opponent", "Winning Team" from pbks union all
		select "Match Number", "Team", "Opponent", "Winning Team" from rr union all
		select "Match Number", "Team", "Opponent", "Winning Team" from gt union all
		select "Match Number", "Team", "Opponent", "Winning Team" from dc union all
		select "Match Number", "Team", "Opponent", "Winning Team" from srh union all
		select "Match Number", "Team", "Opponent", "Winning Team" from lsg union all
		select "Match Number", "Team", "Opponent", "Winning Team" from mi
	) as combined_teams
	where winning_team not in ('Rain Interrupted (No Result)')
),

teams as (
	select v.team, v.match_number, v.opponent, sum(sixes) as sixes from (
		select 'Royal Challengers Bengaluru' as team, "Match Number" as match_number, "Opponent" as opponent, "Sixes" as sixes from "rcb-batters" as t  union all
		select 'Chennai Super Kings', "Match Number" as match_number, "Opponent", "Sixes" as sixes from "csk-batters" as t union all
		select 'Mumbai Indians', "Match Number" as match_number, "Opponent", "Sixes" as sixes from "mi-batters" as t union all
		select 'Kolkata Knight Riders', "Match Number" as match_number, "Opponent", "Sixes" as sixes from "kkr-batters" as t union all
		select 'Rajasthan Royals', "Match Number" as match_number, "Opponent", "Sixes" as sixes from "rr-batters" as t union all
		select 'Delhi Capitals', "Match Number" as match_number, "Opponent", "Sixes" as sixes from "dc-batters" as t union all
		select 'Lucknow Super Giants', "Match Number" as match_number, "Opponent", "Sixes" as sixes from "lsg-batters" as t union all
		select 'Sunrisers Hyderabad', "Match Number" as match_number, "Opponent", "Sixes" as sixes from "srh-batters" as t union all
		select 'Gujarat Titans', "Match Number" as match_number, "Opponent", "Sixes" as sixes from "gt-batters" as t union all
		select 'Punjab Kings', "Match Number" as match_number, "Opponent", "Sixes" as sixes from "pbks-batters" as t
	) as t
	join valid_ipl v on v.match_number = t.match_number
	and v.team = t.team and v.opponent = t.opponent
	group by v.team, v.match_number, v.opponent
)

select team as "Team", count(*) as "Matches With Less Than 6-Sixes" from teams where sixes < 6 group by team order by count(*) desc

-- 67) Which player had the most zeroes (duck outs)?

with valid_ipl as (
	select match_number, team, opponent, winning_team from (
		select "Match Number" as match_number, "Team" as team, "Opponent" as opponent, "Winning Team" as winning_team from rcb union all
		select "Match Number", "Team", "Opponent", "Winning Team" from csk union all
		select "Match Number", "Team", "Opponent", "Winning Team" from kkr union all
		select "Match Number", "Team", "Opponent", "Winning Team" from pbks union all
		select "Match Number", "Team", "Opponent", "Winning Team" from rr union all
		select "Match Number", "Team", "Opponent", "Winning Team" from gt union all
		select "Match Number", "Team", "Opponent", "Winning Team" from dc union all
		select "Match Number", "Team", "Opponent", "Winning Team" from srh union all
		select "Match Number", "Team", "Opponent", "Winning Team" from lsg union all
		select "Match Number", "Team", "Opponent", "Winning Team" from mi
	) as combined_teams
	where winning_team not in ('Rain Interrupted (No Result)','Tie')
),

teams_batting as (
	select team, opponent, match_number, batter, runs_scored, count(*) as ducks from (
		select 'Royal Challengers Bengaluru' as team, "Opponent" as opponent, "Match Number" as match_number, "Batter Name" as batter, "Runs Scored" as runs_scored from "rcb-batters" union all
		select 'Chennai Super Kings', "Opponent", "Match Number", "Batter Name", "Runs Scored" from "csk-batters" union all
		select 'Kolkata Knight Riders', "Opponent", "Match Number", "Batter Name", "Runs Scored" from "kkr-batters" union all
		select 'Punjab Kings', "Opponent", "Match Number", "Batter Name", "Runs Scored" from "pbks-batters" union all
		select 'Rajasthan Royals', "Opponent", "Match Number", "Batter Name", "Runs Scored" from "rr-batters" union all
		select 'Gujarat Titans', "Opponent", "Match Number", "Batter Name", "Runs Scored" from "gt-batters" union all
		select 'Delhi Capitals', "Opponent", "Match Number", "Batter Name", "Runs Scored" from "dc-batters" union all
		select 'Sunrisers Hyderabad', "Opponent", "Match Number", "Batter Name", "Runs Scored" from "srh-batters" union all
		select 'Lucknow Super Giants', "Opponent", "Match Number", "Batter Name", "Runs Scored" from "lsg-batters" union all
		select 'Mumbai Indians', "Opponent", "Match Number", "Batter Name", "Runs Scored" from "mi-batters"
	) as all_batting
	where runs_scored = 0
	group by team, opponent, match_number, batter, runs_scored
)

select batter as "Batter", count(*) as "Ducks" from teams_batting bat
where exists 
( select 1 from valid_ipl i where
	i.match_number = bat.match_number
	and i.team = bat.team
	and i.opponent = bat.opponent )
group by batter
order by "Ducks" desc limit 10

-- 68) How many matches had both teams scoring 170+?

select count(*) as "Number of Times Both Teams Scoring 170+ Runs in a Match" from ipl
-- select "Match Number", "Home Team", "Away Team", "Home Team Score", "Away Team Score", "Winning Team" from ipl
where "Home Team Score" >= 170 and "Away Team Score" >= 170 and "Winning Team" not in ('Rain Interrupted (No Result)')

-- 69) Which batter had the widest distribution (scored in all regions) [Top-10]?

select
	"Batter Name",
	sum(case when "Third Man" > 0 then 1 else 0 end) +
    sum(case when "Point" > 0 then 1 else 0 end) +
    sum(case when "Cover" > 0 then 1 else 0 end) +
    sum(case when "Long Off" > 0 then 1 else 0 end) +
    sum(case when "Fine Leg" > 0 then 1 else 0 end) +
    sum(case when "Square Leg" > 0 then 1 else 0 end) +
    sum(case when "Mid Wicket" > 0 then 1 else 0 end) +
    sum(case when "Long On" > 0 then 1 else 0 end) as "Number of Regions Scored In",
    sum("Third Man") as "Scored in Third Man",
    sum("Point") as "Scored in Point",
    sum("Cover") as "Scored in Cover",
    sum("Long Off") as "Scored in Long Off",
    sum("Fine Leg") as "Scored in Fine Leg",
    sum("Square Leg") as "Scored in Square Leg",
    sum("Mid Wicket") as "Scored in Mid Wicket",
    sum("Long On") as "Scored in Long On",
	sum("Runs Scored") as "Total Runs Scored"
from "ipl-batters"
group by "Batter Name"
having (
	sum(case when "Third Man" > 0 then 1 else 0 end) +
    sum(case when "Point" > 0 then 1 else 0 end) +
    sum(case when "Cover" > 0 then 1 else 0 end) +
    sum(case when "Long Off" > 0 then 1 else 0 end) +
    sum(case when "Fine Leg" > 0 then 1 else 0 end) +
    sum(case when "Square Leg" > 0 then 1 else 0 end) +
    sum(case when "Mid Wicket" > 0 then 1 else 0 end) +
    sum(case when "Long On" > 0 then 1 else 0 end)
	) = 8
order by "Total Runs Scored" desc limit 10

-- 70) Which team had the most powerplays with no wickets?

with valid_ipl as (
	select * from ipl
	where "Winning Team" not in ('Rain Interrupted (No Result)','Tie')
),

filter_overwise as (
	select * from "ipl-overwise" o
	where "Over Number" = 6
	and exists (
		select "Match Number" from valid_ipl i
		where i."Match Number" = o."Match Number"
	)
),

no_pp_wickets as (
	select team, wickets_in_powerplay, count(*) as no_wickets_in_pp from (
		select "Home Team" as team, "Away Team Wickets" as wickets_in_powerplay from filter_overwise union all
		select "Away Team", "Home Team Wickets" from filter_overwise
	) as combined_powerplays
	where wickets_in_powerplay = 0
	group by team, wickets_in_powerplay
)

select team as "Team", no_wickets_in_pp as "Number of Matches with no Wickets in Powerplay" from no_pp_wickets order by no_wickets_in_pp desc

-- 71) Who were the Top-3 consistent players per team (bat or bowl)?

with all_teams_batters as (
	select team, batter, sum(runs_scored) as runs_scored, row_number() over (partition by team order by sum(runs_scored) desc) as rn from (
		select 'Royal Challengers Bengaluru' as team, "Batter Name" as batter, "Runs Scored" as runs_scored from "rcb-batters" union all
		select 'Chennai Super Kings', "Batter Name", "Runs Scored" from "csk-batters" union all
		select 'Kolkata Knight Riders', "Batter Name", "Runs Scored" from "kkr-batters" union all
		select 'Punjab Kings', "Batter Name", "Runs Scored" from "pbks-batters" union all
		select 'Rajasthan Royals', "Batter Name", "Runs Scored" from "rr-batters" union all
		select 'Delhi Capitals', "Batter Name", "Runs Scored" from "dc-batters" union all
		select 'Lucknow Super Giants', "Batter Name", "Runs Scored" from "lsg-batters" union all
		select 'Gujarat Titans', "Batter Name", "Runs Scored" from "gt-batters" union all
		select 'Sunrisers Hyderabad', "Batter Name", "Runs Scored" from "srh-batters" union all
		select 'Mumbai Indians', "Batter Name", "Runs Scored" from "mi-batters"
	) as batters
	where batter notnull
	group by team, batter
),

all_teams_bowlers as (
	select team, bowler, sum(wickets_taken) as wickets_taken, row_number() over (partition by team order by sum(wickets_taken) desc) as rn from (
		select 'Royal Challengers Bengaluru' as team, "Bowler Name" as bowler, "Wickets Taken" as wickets_taken from "rcb-bowlers" union all
		select 'Chennai Super Kings', "Bowler Name", "Wickets Taken" from "csk-bowlers" union all
		select 'Kolkata Knight Riders', "Bowler Name", "Wickets Taken" from "kkr-bowlers" union all
		select 'Punjab Kings', "Bowler Name", "Wickets Taken" from "pbks-bowlers" union all
		select 'Rajasthan Royals', "Bowler Name", "Wickets Taken" from "rr-bowlers" union all
		select 'Delhi Capitals', "Bowler Name", "Wickets Taken" from "dc-bowlers" union all
		select 'Lucknow Super Giants', "Bowler Name", "Wickets Taken" from "lsg-bowlers" union all
		select 'Gujarat Titans', "Bowler Name", "Wickets Taken" from "gt-bowlers" union all
		select 'Sunrisers Hyderabad', "Bowler Name", "Wickets Taken" from "srh-bowlers" union all
		select 'Mumbai Indians', "Bowler Name", "Wickets Taken" from "mi-bowlers"
	) as bowlers
	where bowler notnull
	group by team, bowler
),

ranked_batters as ( select rn, team, batter, runs_scored from all_teams_batters where rn <= 3 ),
ranked_bowlers as ( select rn, team, bowler, wickets_taken from all_teams_bowlers where rn <= 3 ),

combined_top3 as (
	select
		bat.team as team, bat.batter as batter, bat.runs_scored as runs_scored,
		ball.bowler as bowler, ball.wickets_taken as wickets_taken
	from ranked_batters bat
	join ranked_bowlers ball on bat.team = ball.team and bat.rn = ball.rn
)

select
	team as "Team",
	batter as "Top-3 Batters for the Team",
	runs_scored as "Total Runs Scored",
	bowler as "Top-3 Bowlers for the Team",
	wickets_taken as "Total Wickets Taken"
from combined_top3

-- 72) Who were the “Comeback-Players” (Bad First-Half, Strong Second-Half)?

with valid_ipl as (
	select * from rcb union all
	select * from csk union all
	select * from kkr union all
	select * from mi union all
	select * from pbks union all
	select * from rr union all
	select * from gt union all
	select * from lsg union all
	select * from dc union all
	select * from srh
	where "Winning Team" not in ('Rain Interrupted (No Result)','Tie')
),

first_half_teams as ( select * from valid_ipl where "Match Number" <= 7 ),
second_half_teams as ( select * from valid_ipl where "Match Number" >= 8 ),

first_half_batters as (
	select team, batter, sum(runs_scored) as runs_scored from (
		select 'Royal Challengers Bengaluru' as team, "Match Number" as match_number, "Batter Name" as batter, "Runs Scored" as runs_scored from "rcb-batters" union all
		select 'Chennai Super Kings', "Match Number", "Batter Name", "Runs Scored" from "csk-batters" union all
		select 'Kolkata Knight Riders', "Match Number", "Batter Name", "Runs Scored" from "kkr-batters" union all
		select 'Punjab Kings', "Match Number", "Batter Name", "Runs Scored" from "pbks-batters" union all
		select 'Rajasthan Royal', "Match Number", "Batter Name", "Runs Scored" from "rr-batters" union all
		select 'Gujarat Titans', "Match Number", "Batter Name", "Runs Scored" from "gt-batters" union all
		select 'Delhi Capitals', "Match Number", "Batter Name", "Runs Scored" from "dc-batters" union all
		select 'Sunrisers Hyderabad', "Match Number", "Batter Name", "Runs Scored" from "srh-batters" union all
		select 'Lucknow Super Giants', "Match Number", "Batter Name", "Runs Scored" from "lsg-batters" union all
		select 'Mumbai Indians', "Match Number", "Batter Name", "Runs Scored" from "mi-batters"
	) as fhb
	where match_number <= 7
	and batter notnull
	and exists ( select "Match Number" from first_half_teams fht where fht."Match Number" = fhb.match_number )
	group by team, batter
),

second_half_batters as (
	select team, batter, sum(runs_scored) as runs_scored from (
		select 'Royal Challengers Bengaluru' as team, "Match Number" as match_number, "Batter Name" as batter, "Runs Scored" as runs_scored from "rcb-batters" union all
		select 'Chennai Super Kings', "Match Number", "Batter Name", "Runs Scored" from "csk-batters" union all
		select 'Kolkata Knight Riders', "Match Number", "Batter Name", "Runs Scored" from "kkr-batters" union all
		select 'Punjab Kings', "Match Number", "Batter Name", "Runs Scored" from "pbks-batters" union all
		select 'Rajasthan Royal', "Match Number", "Batter Name", "Runs Scored" from "rr-batters" union all
		select 'Gujarat Titans', "Match Number", "Batter Name", "Runs Scored" from "gt-batters" union all
		select 'Delhi Capitals', "Match Number", "Batter Name", "Runs Scored" from "dc-batters" union all
		select 'Sunrisers Hyderabad', "Match Number", "Batter Name", "Runs Scored" from "srh-batters" union all
		select 'Lucknow Super Giants', "Match Number", "Batter Name", "Runs Scored" from "lsg-batters" union all
		select 'Mumbai Indians', "Match Number", "Batter Name", "Runs Scored" from "mi-batters"
	) as shb
	where match_number >= 8
	and batter notnull
	and exists ( select "Match Number" from second_half_teams sht where sht."Match Number" = shb.match_number )
	group by team, batter
),

batters_comeback as (
	select
		fhb.team as "Team",
		fhb.batter as "Batter Name",
		fhb.runs_scored as "Runs Scored in First-Half",
		shb.runs_scored as "Runs Scored in Second-Half"
	from first_half_batters fhb
	join second_half_batters shb on shb.team = fhb.team and fhb.batter = shb.batter
	where shb.runs_scored > fhb.runs_scored
),

--

first_half_bowlers as (
	select team, bowler, sum(wickets_taken) as wickets_taken from (
		select 'Royal Challengers Bengaluru' as team, "Match Number" as match_number, "Bowler Name" as bowler, "Wickets Taken" as wickets_taken from "rcb-bowlers" union all
		select 'Chennai Super Kings', "Match Number", "Bowler Name", "Wickets Taken" from "csk-bowlers" union all
		select 'Kolkata Knight Riders', "Match Number", "Bowler Name", "Wickets Taken" from "kkr-bowlers" union all
		select 'Punjab Kings', "Match Number", "Bowler Name", "Wickets Taken" from "pbks-bowlers" union all
		select 'Rajasthan Royal', "Match Number", "Bowler Name", "Wickets Taken" from "rr-bowlers" union all
		select 'Gujarat Titans', "Match Number", "Bowler Name", "Wickets Taken" from "gt-bowlers" union all
		select 'Delhi Capitals', "Match Number", "Bowler Name", "Wickets Taken" from "dc-bowlers" union all
		select 'Sunrisers Hyderabad', "Match Number", "Bowler Name", "Wickets Taken" from "srh-bowlers" union all
		select 'Lucknow Super Giants', "Match Number", "Bowler Name", "Wickets Taken" from "lsg-bowlers" union all
		select 'Mumbai Indians', "Match Number", "Bowler Name", "Wickets Taken" from "mi-bowlers"
	) as fhb
	where match_number <= 7
	and bowler notnull
	and exists ( select "Match Number" from first_half_teams fht where fht."Match Number" = fhb.match_number )
	group by team, bowler
),

second_half_bowlers as (
	select team, bowler, sum(wickets_taken) as wickets_taken from (
		select 'Royal Challengers Bengaluru' as team, "Match Number" as match_number, "Bowler Name" as bowler, "Wickets Taken" as wickets_taken from "rcb-bowlers" union all
		select 'Chennai Super Kings', "Match Number", "Bowler Name", "Wickets Taken" from "csk-bowlers" union all
		select 'Kolkata Knight Riders', "Match Number", "Bowler Name", "Wickets Taken" from "kkr-bowlers" union all
		select 'Punjab Kings', "Match Number", "Bowler Name", "Wickets Taken" from "pbks-bowlers" union all
		select 'Rajasthan Royal', "Match Number", "Bowler Name", "Wickets Taken" from "rr-bowlers" union all
		select 'Gujarat Titans', "Match Number", "Bowler Name", "Wickets Taken" from "gt-bowlers" union all
		select 'Delhi Capitals', "Match Number", "Bowler Name", "Wickets Taken" from "dc-bowlers" union all
		select 'Sunrisers Hyderabad', "Match Number", "Bowler Name", "Wickets Taken" from "srh-bowlers" union all
		select 'Lucknow Super Giants', "Match Number", "Bowler Name", "Wickets Taken" from "lsg-bowlers" union all
		select 'Mumbai Indians', "Match Number", "Bowler Name", "Wickets Taken" from "mi-bowlers"
	) as shb
	where match_number >= 8
	and bowler notnull
	and exists ( select "Match Number" from second_half_teams sht where sht."Match Number" = shb.match_number )
	group by team, bowler
),

bowlers_comeback as (
	select
		fhb.team as "Team",
		fhb.bowler as "Bowler Name",
		fhb.wickets_taken as "Wickets Taken in First-Half",
		shb.wickets_taken as "Wickets Taken in Second-Half"
	from first_half_bowlers fhb
	join second_half_bowlers shb on shb.team = fhb.team and fhb.bowler = shb.bowler
	where shb.wickets_taken > fhb.wickets_taken
)

select * from batters_comeback order by "Team"
select * from bowlers_comeback order by "Team"

-- 73) Who had given performances but in losing causes (Unfortunate Performers)?

with valid_ipl as (
	select match_number, team, opponent, batter, bowler from (
		select "Match Number" as match_number, "Team" as team, "Opponent" as opponent, "RCB Best Batsman" as batter, "RCB Best Bowler" as bowler, "Winning Team" as winning_team from rcb union all
		select "Match Number", "Team", "Opponent", "CSK Best Batsman", "CSK Best Bowler", "Winning Team" from csk union all
		select "Match Number", "Team", "Opponent", "KKR Best Batsman", "KKR Best Bowler", "Winning Team" from kkr union all
		select "Match Number", "Team", "Opponent", "PBKS Best Batsman", "PBKS Best Bowler", "Winning Team" from pbks union all
		select "Match Number", "Team", "Opponent", "RR Best Batsman", "RR Best Bowler", "Winning Team" from rr union all
		select "Match Number", "Team", "Opponent", "GT Best Batsman", "GT Best Bowler", "Winning Team" from gt union all
		select "Match Number", "Team", "Opponent", "DC Best Batsman", "DC Best Bowler", "Winning Team" from dc union all
		select "Match Number", "Team", "Opponent", "SRH Best Batsman", "SRH Best Bowler", "Winning Team" from srh union all
		select "Match Number", "Team", "Opponent", "LSG Best Batsman", "LSG Best Bowler", "Winning Team" from lsg union all
		select "Match Number", "Team", "Opponent", "MI Best Batsman", "MI Best Bowler", "Winning Team" from mi
	) as valid_matches
	where winning_team not in ('Rain Interrupted (No Result)','Tie')
	and winning_team != team and batter notnull and bowler notnull
),

all_teams_batting_performances as (
	select batters.match_number as mn, i.team as team, i.opponent as opp, batters.batter as batter, batters.runs_scored as runs, strike_rate from (
		select "Match Number" as match_number, "Batter Name" as batter, "Runs Scored" as runs_scored, round("Strike Rate"::numeric,2) as strike_rate from "rcb-batters" union all
		select "Match Number", "Batter Name", "Runs Scored", round("Strike Rate"::numeric,2) from "csk-batters" union all
		select "Match Number", "Batter Name", "Runs Scored", round("Strike Rate"::numeric,2) from "kkr-batters" union all
		select "Match Number", "Batter Name", "Runs Scored", round("Strike Rate"::numeric,2) from "pbks-batters" union all
		select "Match Number", "Batter Name", "Runs Scored", round("Strike Rate"::numeric,2) from "dc-batters" union all
		select "Match Number", "Batter Name", "Runs Scored", round("Strike Rate"::numeric,2) from "gt-batters" union all
		select "Match Number", "Batter Name", "Runs Scored", round("Strike Rate"::numeric,2) from "mi-batters" union all
		select "Match Number", "Batter Name", "Runs Scored", round("Strike Rate"::numeric,2) from "srh-batters" union all
		select "Match Number", "Batter Name", "Runs Scored", round("Strike Rate"::numeric,2) from "lsg-batters" union all
		select "Match Number", "Batter Name", "Runs Scored", round("Strike Rate"::numeric,2) from "rr-batters"
	) batters
	join valid_ipl i on i.match_number = batters.match_number and i.batter = batters.batter
),

all_teams_bowling_performances as (
	select bowlers.match_number as mn, i.team as team, i.opponent as opp, bowlers.bowler as bowler, bowlers.wickets_taken as wickets, economy from (
		select "Match Number" as match_number, "Bowler Name" as bowler, "Wickets Taken" as wickets_taken, round("Economy"::numeric,2) as economy from "rcb-bowlers" union all
		select "Match Number", "Bowler Name", "Wickets Taken", round("Economy"::numeric,2) from "csk-bowlers" union all
		select "Match Number", "Bowler Name", "Wickets Taken", round("Economy"::numeric,2) from "kkr-bowlers" union all
		select "Match Number", "Bowler Name", "Wickets Taken", round("Economy"::numeric,2) from "pbks-bowlers" union all
		select "Match Number", "Bowler Name", "Wickets Taken", round("Economy"::numeric,2) from "dc-bowlers" union all
		select "Match Number", "Bowler Name", "Wickets Taken", round("Economy"::numeric,2) from "gt-bowlers" union all
		select "Match Number", "Bowler Name", "Wickets Taken", round("Economy"::numeric,2) from "mi-bowlers" union all
		select "Match Number", "Bowler Name", "Wickets Taken", round("Economy"::numeric,2) from "srh-bowlers" union all
		select "Match Number", "Bowler Name", "Wickets Taken", round("Economy"::numeric,2) from "lsg-bowlers" union all
		select "Match Number", "Bowler Name", "Wickets Taken", round("Economy"::numeric,2) from "rr-bowlers"
	) bowlers
	join valid_ipl i on i.match_number = bowlers.match_number and i.bowler = bowlers.bowler
),

combined_losing_cause_performances as (
	select
		bat.mn, bat.team as team, bat.opp as opp, bat.batter as batter, bat.runs as runs, bat.strike_rate as strike_rate,
		ball.bowler as bowler, ball.wickets as wickets, ball.economy as economy
	from all_teams_batting_performances bat
	join all_teams_bowling_performances ball on bat.mn = ball.mn and bat.team = ball.team and bat.opp = ball.opp
)

select
	team as "Team",
	opp as "Opponent",
	batter as "Batter Name",
	runs as "Highest Runs Scored in Losing Cause",
	strike_rate as "Batting Strike Rate",
	bowler as "Bowler Name",
	wickets as "Wickets Taken in Losing Cause",
	economy as "Bowling Economy",
	opp as "Winning Team"
from combined_losing_cause_performances
order by "Highest Runs Scored in Losing Cause" desc, "Wickets Taken in Losing Cause" desc
limit 10