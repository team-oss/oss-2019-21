CREATE materialized VIEW gh_validation.sectors AS (
    SELECT
        year,
        sum(us) us,
        sum(academic) academic,
        sum(bs) bs,
        sum(gov) gov,
        sum(npish) npish,
        sum(hh) hh
    FROM
        gh_validation.sectors_slug_year_personmonths
    GROUP BY
        year
    ORDER BY
        year
);

ALTER TABLE
    IF EXISTS gh_validation.sectors OWNER TO ncses_oss;
