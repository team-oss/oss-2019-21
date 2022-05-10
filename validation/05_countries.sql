CREATE materialized VIEW gh_validation.countries AS (
    WITH a AS(
        SELECT
            a.slug,
            a.year,
            country,
            personmonths * b.additions / a.additions personmonths
        FROM
            gh_validation.slug_year_additions_personmonths a
            INNER JOIN gh_validation.by_country b ON a.slug = b.slug
            AND a.year = b.year
            AND b.additions > 0
    )
    SELECT
        year,
        country,
        sum(personmonths) personmonths
    FROM
        a
    GROUP BY
        year,
        country
    ORDER BY
        year,
        country
);

ALTER TABLE
    IF EXISTS gh_validation.countries OWNER TO ncses_oss;
