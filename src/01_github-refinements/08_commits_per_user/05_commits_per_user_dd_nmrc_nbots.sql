-- gh.commits_per_user_dd_nmrc_nbots

CREATE MATERIALIZED VIEW gh_cost.commits_per_user_dd_nmrc_nbots AS (

WITH A AS (
	SELECT login, slug, EXTRACT(YEAR FROM committed_date)::int AS year
	FROM gh.commits_dd_nmrc_nbots
	WHERE login IS NOT NULL AND login != 'null'
), B AS (
	SELECT slug, year, login, COUNT(*) AS commits
	FROM A
	GROUP BY slug, year, login
)

SELECT login, slug, commits, year
FROM B
ORDER BY commits DESC

);

CREATE INDEX login_cpu_dd_nmrc_nbots_idx ON gh_cost.commits_per_user_dd_nmrc_nbots (login);
GRANT ALL PRIVILEGES ON gh_cost.commits_per_user_dd_nmrc_nbots TO ncses_oss;
