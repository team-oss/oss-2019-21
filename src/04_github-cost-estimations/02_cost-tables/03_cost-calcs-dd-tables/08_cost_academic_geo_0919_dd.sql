
---- cost by academic/nonacademic sector and then by country

CREATE MATERIALIZED VIEW gh.cost_academic_geo_0919 AS (
WITH table_join AS (
SELECT slug, C.login, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(COALESCE(sector, 'null/missing'),
			 'business', 'non-academic'), 'government', 'non-academic'), 'household', 'non-academic'),
			 'non-profit', 'non-academic'), 'not classified', 'non-academic') AS sector,
		COALESCE(country, 'Missing') AS inst_country,
		additions, deletions, EXTRACT(YEAR FROM committed_date)::int AS year
FROM gh.commits_raw AS C
LEFT JOIN (SELECT A.login, A.sector, B.country
FROM gh.cost_logins_w_sector_info AS A
LEFT JOIN gh.sna_ctr_academic AS B
ON A.login = B.login ) AS D
ON C.login = D.login
)

GRANT ALL PRIVILEGES ON TABLE gh.cost_academic_geo_0919 TO ncses_oss;

SELECT slug, sector, inst_country, COUNT(*) AS commits, SUM(additions) AS additions, SUM(deletions) AS deletions,
					SUM(additions + deletions) AS sum_adds_dels, SUM(additions - deletions) AS net_adds_dels
FROM table_join
WHERE year > 2008 AND year < 2020
GROUP BY slug, sector, inst_country
ORDER BY slug, sector, inst_country
);
