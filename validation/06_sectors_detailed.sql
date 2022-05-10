CREATE materialized VIEW gh_validation.sectors_slug_year_personmonths AS (
    WITH a AS (
        SELECT
            slug,
            year,
            sum(us_additions) us_additions,
            sum(us_acad_frac) us_acad_frac,
            sum(us_bus_frac) us_bus_frac,
            sum(us_gov_frac) us_gov_frac,
            sum(us_np_frac) us_np_frac,
            sum(us_hh_frac) us_hh_frac
        FROM
            gh_cost.cost_us_frac_by_sector_0919_lchn_110621
        GROUP BY
            slug,
            year
    )
    SELECT
        a.slug,
        b.year,
        personmonths * us_additions / additions us,
        personmonths * us_acad_frac / additions academic,
        personmonths * us_bus_frac / additions bs,
        personmonths * us_gov_frac / additions gov,
        personmonths * us_np_frac / additions npish,
        personmonths * us_hh_frac / additions hh
    FROM
        a
        INNER JOIN gh_validation.slug_year_additions_personmonths b ON a.slug = b.slug
        AND a.year = b.year
        AND additions > 0
    ORDER BY
        slug,
        year
);

ALTER TABLE
    IF EXISTS gh_validation.sectors_slug_year_personmonths OWNER TO ncses_oss;
