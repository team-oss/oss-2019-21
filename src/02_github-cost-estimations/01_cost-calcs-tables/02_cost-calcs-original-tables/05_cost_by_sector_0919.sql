
---third, we want all the commits, additions, deletions, sum and net by sector (2008-2019)

CREATE MATERIALIZED VIEW gh.cost_by_sector_0919 AS (
WITH sector_join AS (
SELECT slug, A.login, COALESCE(B.sector, 'null/missing') AS sector, A.additions, A.deletions,
                      EXTRACT(YEAR FROM A.committed_date)::int AS year
FROM gh.commits_raw A
LEFT JOIN gh.cost_logins_w_sector_info AS B
ON A.login = B.login
)

GRANT ALL PRIVILEGES ON TABLE gh.cost_by_sector_0919 TO ncses_oss;

SELECT slug, sector, COUNT(*) AS commits, SUM(additions) AS additions, SUM(deletions) AS deletions,
					SUM(additions + deletions) AS sum_adds_dels, SUM(additions - deletions) AS net_adds_dels
FROM sector_join
WHERE year > 2008 AND year < 2020
GROUP BY slug, sector
ORDER BY slug DESC
);

