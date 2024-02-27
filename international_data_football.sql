CREATE SCHEMA internationalFootballDb;

CREATE TABLE goal_scorers
(
	date DATE,
    home_team VARCHAR(50),
    away_team VARCHAR(50),
    team VARCHAR(50),
    scorer VARCHAR(50),
    minute INT,
    own_goal VARCHAR(50),
    penalty VARCHAR(50)
);

SELECT * FROM goal_scorers;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/goalscorers.csv' INTO TABLE goal_scorers
FIELDS TERMINATED BY ','
IGNORE 1 LINES;

-- COUNTING THE NUMBER OF GOALS SCORED
SELECT COUNT(*) as num_goals
FROM goal_scorers;

-- COUNTING THE NUMBER OF MATCHES PLAYED
SELECT COUNT(*) AS num_matches
FROM
	( SELECT date
	FROM goal_scorers
	GROUP BY date, home_team, away_team
	) AS subquery;

-- COUNTING THE NUMBER OF GOALS SCORED PER MATCH
SELECT COUNT(*) as num_goals, CONCAT(home_team, " vs ", away_team) as teams_playing
FROM goal_scorers
GROUP BY date, home_team, away_team
ORDER BY num_goals DESC
LIMIT 10;

-- COUNTING THE PENALTY VS NON-PENALTY GOALS
SELECT penalty, COUNT(*) as count, COUNT(*) * 100 / (SELECT COUNT(*) FROM goal_scorers) as percentage
FROM goal_scorers
GROUP BY penalty;

-- COUNTING THE OWN GOALS VS NON-OWN GOALS
SELECT own_goal, COUNT(*) as count, COUNT(*) * 100 / (SELECT COUNT(*) FROM goal_scorers) as percentage
FROM goal_scorers
GROUP BY own_goal;

-- COUNTING THE NUMBER OF GOALS FOR EACH YEAR
SELECT EXTRACT(YEAR FROM date) as date_year, COUNT(*) as goals_num
FROM goal_scorers
GROUP BY date_year
ORDER BY date_year ASC;

-- COUNTING THE NUMBER OF GOALS FOR EACH YEAR (MIN)
SELECT EXTRACT(YEAR FROM date) as date_year, COUNT(*) as goals_num
FROM goal_scorers
GROUP BY date_year
ORDER BY goals_num ASC
LIMIT 10;

-- COUNTING THE NUMBER OF GOALS FOR EACH TEAM (MAX)
SELECT COUNT(*) as goals_num, home_team
FROM goal_scorers
GROUP BY home_team
ORDER BY goals_num DESC
LIMIT 10;

-- COUNTING THE NUMBER OF GOALS FOR EACH TEAM (MIN)
SELECT COUNT(*) as goals_num, home_team
FROM goal_scorers
GROUP BY home_team
ORDER BY goals_num ASC
LIMIT 10;

-- COUNTING THE NUMBER OF HOME GOALS VS AWAY GOALS
SELECT
SUM(CASE WHEN home_team = team THEN 1 ELSE 0 END) as home_goals,
SUM(CASE WHEN away_team = team THEN 1 ELSE 0 END) as away_goals
FROM goal_scorers;

-- SELECTING THE TOP 10 GOAL SCORERS
SELECT COUNT(*) as goals_num, scorer
FROM goal_scorers
GROUP BY scorer
ORDER BY goals_num DESC
LIMIT 10;

-- SELECTING THE 10 MINUTES WHERE THE MOST GOALS SCORED
SELECT COUNT(*) as goals_num, minute
FROM goal_scorers
GROUP BY minute
ORDER BY goals_num DESC
LIMIT 10;

-- SELECTING THE 10 MINUTES WHERE THE LEAST GOALS SCORED
SELECT COUNT(*) as goals_num, minute
FROM goal_scorers
GROUP BY minute
ORDER BY goals_num ASC
LIMIT 10;

-- DIVIDING THE MINUTES AT WHICH GOALS WHERE SCORED INTO 15 MINS TIMESPANS
-- AND CALCULATING THE NUMBER OF GOALS FOR EACH TIMESPAN
SELECT
    time_span,
    COUNT(*) AS count
FROM (
    SELECT
        CONCAT(
            FLOOR((minute - 1) / 15) * 15 + 1,
            '-',
            FLOOR((minute - 1) / 15) * 15 + 15
        ) AS time_span,
        minute
    FROM goal_scorers
) AS subquery
GROUP BY time_span
ORDER BY count DESC;

-- COUNTING THE NUMBER OF GOALS PER HALF (45 MINS)
SELECT
    COUNT(*) AS count,
    (CASE
		WHEN time_span = '1-45' THEN 'First Half'
        WHEN time_span = '46-90' THEN 'Second Half'
        ELSE 'Extra Time'
	END) as time
FROM (
    SELECT
        CONCAT(
            FLOOR((minute - 1) / 45) * 45 + 1,
            '-',
            FLOOR((minute - 1) / 45) * 45 + 45
        ) AS time_span,
        minute
    FROM goal_scorers
) AS subquery
GROUP BY time_span, time
ORDER BY count DESC;

-- TOP SCORER EACH YEAR
WITH top_scorer_count AS (
	WITH goals_per_year AS (
		SELECT
			COUNT(*) as goals_num,
			EXTRACT(YEAR FROM date) as date_year,
			scorer
		FROM goal_scorers
		GROUP BY date_year, scorer
	)
	SELECT
		a.*
	FROM
		goals_per_year a
	JOIN
	(
		SELECT MAX(goals_num) as max_goals, date_year
		FROM goals_per_year
		GROUP BY date_year
	) b
	ON
		a.date_year = b.date_year
		AND a.goals_num = b.max_goals
	GROUP BY
		a.date_year,
		a.scorer
)
-- NUMBER OF TIMES A PLAYER WAS A TOP SCORER IN A YEAR
SELECT COUNT(*) AS top_scorer_count, scorer
FROM top_scorer_count
GROUP BY scorer
ORDER BY top_scorer_count DESC
LIMIT 10;

SELECT * FROM goal_scorers;

-- SELECTING WHICH TEAM SCORES THE MOST EVERY MINUTE
WITH team_minute AS (
	SELECT COUNT(*) as goals_num, team, minute
	FROM goal_scorers
	GROUP BY team, minute
	ORDER BY goals_num DESC
)
SELECT a.*
FROM team_minute a
JOIN
(
	SELECT MAX(goals_num) as max_goals, minute
    FROM team_minute
    GROUP BY minute
) b
ON a.minute = b.minute AND a.goals_num = b.max_goals
ORDER BY minute;

-- NUMBER OF MINUTES A TEAM SCORED THE MOST GOALS
WITH team_minute_number AS (
	WITH team_minute AS (
		SELECT COUNT(*) as goals_num, team, minute
		FROM goal_scorers
		GROUP BY team, minute
		ORDER BY goals_num DESC
	)
	SELECT a.*
	FROM team_minute a
	JOIN
	(
		SELECT MAX(goals_num) as max_goals, minute
		FROM team_minute
		GROUP BY minute
	) b
	ON a.minute = b.minute AND a.goals_num = b.max_goals
	ORDER BY minute
)
SELECT COUNT(*) AS num_as_most_goals, team
FROM team_minute_number
GROUP BY team
ORDER BY num_as_most_goals DESC
LIMIT 10;

-- NUMBER OF MINUTES A PLAYER SCORED THE MOST GOALS
WITH scorer_minute_number AS (
	WITH scorer_minute AS (
		SELECT COUNT(*) as goals_num, scorer, minute
		FROM goal_scorers
		GROUP BY scorer, minute
		ORDER BY goals_num DESC
	)
	SELECT a.*
	FROM scorer_minute a
	JOIN
	(
		SELECT MAX(goals_num) as max_goals, minute
		FROM scorer_minute
		GROUP BY minute
	) b
	ON a.minute = b.minute AND a.goals_num = b.max_goals
	ORDER BY a.minute
)
SELECT COUNT(*) AS num_as_most_goals, scorer
FROM scorer_minute_number
GROUP BY scorer
ORDER BY num_as_most_goals DESC
LIMIT 10;