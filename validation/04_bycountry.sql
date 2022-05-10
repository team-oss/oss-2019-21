CREATE materialized VIEW gh_validation.by_country AS (
    WITH a AS (
        SELECT
            slug,
            year,
            a.login,
            country,
            fraction * additions additions
        FROM
            gh_validation.slug_year_login_additions a
            INNER JOIN gh_cost.user_country_fractions b ON a.login = b.login
    )
    SELECT
        slug,
        year,
        country,
        sum(additions) additions
    FROM
        a
    GROUP BY
        slug,
        year,
        country
);

ALTER TABLE
    IF EXISTS gh_validation.by_country OWNER TO ncses_oss;
