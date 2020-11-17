--before running this script you need to make three tables:
--1) src/01_github-summary-analysis/07_desc_ctrs_summary.sql
--2) src/04_github-sectoring/analysis/01_ctrs_extra.sql
--3) src/04_github-sectoring/analysis/02_sna_ctrs_sectors.Rmd

--once that has finished this code takes the desc_ctrs_summary (github summary data of distinct logins) and
--sna_ctr_sectors (the logins from gh torrent after being sectored during DSPG) and joins them together

CREATE MATERIALIZED VIEW gh.cost_logins_w_sector_info AS (
SELECT A.login, A.repos, A.commits, A.additions, A.deletions,
       B.sector, B.city_info, B.cc_multiple, B.cc_di, B.cc_viz,
	   B.raw_location, B.email, B.company_original, B.company_cleaned
FROM gh.desc_ctrs_summary A
LEFT JOIN gh.sna_ctr_sectors B
ON A.login = B.login
ORDER BY login
);

GRANT ALL PRIVILEGES ON TABLE gh.cost_logins_w_sector_info TO ncses_oss;

--get the counts
WITH new_table AS (
	SELECT COALESCE(sector, 'n/a') AS sector, login, commits, additions, deletions
	FROM gh.cost_logins_w_sector_info
)
SELECT sector, SUM(commits), SUM(additions), SUM(deletions)
FROM new_table
GROUP BY sector;

