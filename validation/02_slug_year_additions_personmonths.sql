CREATE materialized VIEW gh_validation.slug_year_additions_personmonths AS (
	WITH a AS (
		SELECT
			slug,
			year,
			sum(additions) additions
		FROM
			gh_validation.slug_year_login_additions
		GROUP BY
			slug,
			year
	)
	SELECT
		*,
		2.5 * (2.4 * (additions :: float / 1000) ^ 1.05) ^ 0.38 personmonths
	FROM
		a
);

ALTER TABLE
	IF EXISTS gh_validation.slug_year_additions_personmonths OWNER TO ncses_oss;
