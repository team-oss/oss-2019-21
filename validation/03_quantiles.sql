CREATE materialized VIEW gh_validation.quantiles AS (
    WITH a AS (
        SELECT
            personmonths
        FROM
            gh_validation.slug_year_additions_personmonths
        WHERE
            year = 2019
    )
    SELECT
        k,
        percentile_disc(k) within group (
            ORDER BY
                personmonths
        )
    FROM
        a,
        generate_series(0.01, 1, 0.01) AS k
    GROUP BY
        k
);

ALTER TABLE
    IF EXISTS gh_validation.quantiles OWNER TO ncses_oss;
