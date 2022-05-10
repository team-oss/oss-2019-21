CREATE materialized VIEW gh_validation.slug_year_login_additions AS (
	WITH a AS (
		SELECT
			slug,
			extract(
				year
				FROM
					committed_date
			) AS year,
			login,
			additions
		FROM
			gh.commits_dd_nmrc_jbsc
	)
	SELECT
		slug,
		year,
		login,
		sum(additions) additions
	FROM
		a
	GROUP BY
		slug,
		year,
		login
);
ALTER TABLE IF EXISTS gh_validation.slug_year_login_additions
  OWNER TO ncses_oss;
