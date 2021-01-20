
CREATE MATERIALIZED VIEW gh.sna_ctr_edgelist_0812 AS (

WITH C AS (
	SELECT B.slug, B.year, B.login AS ctr1, C.login AS ctr2
	FROM gh.commits_per_user B
	INNER JOIN gh.commits_per_user AS C ON B.year = C.year AND B.slug = C.slug
	WHERE B.login < C.login AND B.login != C.login
	AND B.YEAR BETWEEN 2008 AND 2012 AND C.YEAR BETWEEN 2008 AND 2012
)

SELECT ctr1, ctr2, COUNT(*) AS repo_wts
FROM C
GROUP BY ctr1, ctr2
ORDER BY repo_wts DESC

);

CREATE INDEX sna_ctr_edgelist_0812_ctr1_idx ON gh.sna_ctr_edgelist_0812 (ctr1);
CREATE INDEX sna_ctr_edgelist_0812_ctr2_idx ON gh.sna_ctr_edgelist_0812 (ctr2);
GRANT ALL PRIVILEGES ON gh.sna_ctr_edgelist_0812 TO ncses_oss;
