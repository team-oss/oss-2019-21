using LibPQ: LibPQ, Connection, execute
using DataFrames
using CSV: CSV
using CairoMakie, AlgebraOfGraphics
using Colors
using HTTP: HTTP, URI, request
using JSON3: JSON3

conn = Connection("")

quantiles_data = DataFrame(
    execute(
        conn,
        "SELECT k :: DOUBLE PRECISION x, percentile_disc / 12 y FROM gh_validation.quantiles;",
        not_null = true
        )
    )

quantiles = data(
    subset(quantiles_data, :x => ByRow(<(1)))
    ) *
    mapping(:x, :y) *
    (smooth(degree = 7))
    
quantiles_plt = with_theme(Theme(fontsize = 20)) do
    draw(
        quantiles,
        axis = (;
            limits = ((0, 1), (0, 5)),
            xlabel = "Percentile",
            ylabel = "Size of full-time team",
            xticks = 0:0.1:1,
            )
        )
end

save(joinpath("figs", "quantiles.eps"), quantiles_plt)

countries_data = DataFrame(
    execute(
        conn,
        """
        WITH a AS (
            SELECT
            *
        FROM
            gh_validation.countries
        WHERE
            year > 2008
            AND year < 2020
        ),
        b AS (
            SELECT
                country,
                sum(personmonths) x
            FROM
                a
            GROUP BY
                country
            ORDER BY
                x DESC
            LIMIT
                10
        )
        SELECT
            year :: int, a.country, personmonths
        FROM
            a
        INNER JOIN b ON a.country = b.country;
        """,
        not_null = true
        )
    )

countries = data(countries_data) *
    mapping(
        :year => :nonnumeric,
        :personmonths => (x -> x ./ 12_000),
        color = :country => renamer(
            [
                "United States" => "USA",
                "United Kingdom" => "GBR",
                "Switzerland" => "CHE",
                "Spain" => "SPN",
                "Japan" => "JPN",
                "India" => "IND",
                "Germany" => "DEU",
                "China" => "CHN",
                "Canada" => "CAN",
                "Brazil" => "BRA",
            ],
            ) => "",
        stack = :country => sorter(reverse!(unique(countries_data[!,:country]))) => "Country",) *
    visual(BarPlot)
countries_plt = with_theme(Theme(fontsize = 16)) do
    draw(
        countries,
        axis = (;
            xlabel = "Year",
            ylabel = "Person Years (in 1,000)",
            limits = ((2008.5, 2019.5), (0, 66)),
            xticks = 2009:2019,
            yticks = 0:5:65,
            ),
        palettes = (
            color = COLORS,
            ),
        legend = (
            position = :top,
            titleposition = :left,
            framevisible = false,
            padding = 0)
        )
end

save(joinpath("figs", "countries.eps"), countries_plt)

us = DataFrame(
    execute(
        conn,
        "SELECT year ::int, us, bs, npish, hh, gov, academic from gh_validation.sectors;",
        not_null = true
        )
    )
software = CSV.read(joinpath("data", "software_wages.csv"), DataFrame)

software[17:17,:]

105892 / 106953.8709
36_238 / 36_635

us = innerjoin(us, software, on = :year)
transform!(
    us,
    [:us, :a_mean] => ByRow((pm, was) -> pm * was / 12 * 2.02) => :us,
    [:bs, :a_mean] => ByRow((pm, was) -> pm * was / 12 * 2.02) => :bs,
    [:npish, :a_mean] => ByRow((pm, was) -> pm * was / 12 * 2.02) => :npish,
    [:hh, :a_mean] => ByRow((pm, was) -> pm * was / 12 * 2.02) => :hh,
    [:gov, :a_mean] => ByRow((pm, was) -> pm * was / 12 * 2.02) => :gov,
    [:academic, :a_mean] => ByRow((pm, was) -> pm * was / 12 * 2.02) => :academic,
    )
select!(
    us,
    :year => identity,
    2:7 .=> ByRow(x -> round(Int, x / 1_000_000)),
    renamecols = false,
    )
CSV.write(joinpath("data", "investment.csv"), us)

response = request(
    "GET",
    URI(
        scheme = "https",
        host = "apps.bea.gov",
        path = "/api/data",
        query = append!(
            [
                "UserID" => ENV["API_BEA"],
                "method" => "GetData",
                "DatasetName" => "NIPA",
                "TableName" => "T50604",
                "Frequency" => "A",
                "Year" => join(2009:2019, ','),
                ],
            ),
        )
    )
json = JSON3.read(response.body)
tbl = DataFrame(elem for elem in json.BEAAPI.Results.Data if parse(Int, elem.LineNumber) ∈ 2:5)
oas_pi_2012 = parse.(Float64, subset(tbl, :LineNumber => ByRow(isequal("5")))[!,:DataValue])
oas_pi_2019 = oas_pi_2012 ./ oas_pi_2012[end]

us = CSV.read(joinpath("data", "investment.csv"), DataFrame)
const OAS_DEPRECIATION_RATE = 1 / 3

us_real = transform(
    us,
    Not(1) .=> (x -> x ./ oas_pi_2019),
    renamecols = false,
    )
CSV.write(joinpath("data", "real_investment.csv"), us_real)

function netstock_calc(nominal)
    investment_2019USD = nominal ./ oas_pi_2019
    netstock = [ investment_2019USD[1] / OAS_DEPRECIATION_RATE ]
    for idx in 2:lastindex(investment_2019USD)
        push!(
            netstock,
            netstock[end] + investment_2019USD[idx] - (netstock[end] + investment_2019USD[idx] / 2) * OAS_DEPRECIATION_RATE,
            )
    end
    netstock
end

nominal = us[!,:us]
netstock = netstock_calc(nominal)

us_netstock = transform(
    us,
    :year => identity,
    Not(:year) .=> netstock_calc,
    renamecols = false,
    )
CSV.write(joinpath("data", "netstock.csv"), us_netstock)

stockgrowrates = @views log.(netstock[2:end] ./ netstock[1:end - 1])

netstock_data = DataFrame(year = 2009:2019, current = netstock, growrate = vcat(missing, stockgrowrates))

function netstock_plt_fnc()
    f = Figure()
    ax = Axis(
        f[1,1],
        limits = ((2008.5, 2019.5), (0, 80)),
        xticks = 2009:2019,
        ylabel = "Net-stock (2019 billions \$)",
        xlabel = "Year"
        )
    barplot!(
        ax,
        2009:2019,
        netstock ./ 1_000,
        color = RGBAf(0, 0, 0, 0.25))
    ax = Axis(
        f[2,1],
        limits = ((2009.5, 2019.5), (0, 70)),
        xticks = 2010:2019,
        ylabel = "Log growth (%)",
        xlabel = "Year",
        )
    barplot!(
        ax,
        2010:2019,
        100stockgrowrates,
        color = RGBAf(0, 0, 0, 0.25))
    f
end
fig = with_theme(netstock_plt_fnc, Theme(fontsize = 18))

save(joinpath("figs", "netstock.eps"), fig)

prepackaged_pi = parse.(Float64, subset(tbl, :LineNumber => ByRow(isequal("3")))[!,:DataValue])
prepackaged_pi_2019 = prepackaged_pi ./ prepackaged_pi[end]

lb = nominal
y = investment_2019USD
ub = nominal ./ prepackaged_pi_2019

investment_estimates = DataFrame(
    year = 2009:2019,
    lb = nominal ./ 1000,
    y = investment_2019USD ./ 1000,
    ub = nominal ./ prepackaged_pi_2019 ./ 1000)
plt_investment = data(investment_estimates) *
    mapping(:year, :y, :lb, :ub) *
    visual(
        CrossBar,
        color = RGBAf(0, 0, 0, 0.25))

fig_plt_investment = with_theme(Theme(fontsize = 20)) do
    draw(
        plt_investment,
        axis = (
            xticks = 2009:2019,
            xlabel = "Year",
            ylabel = "Billions of dollars",
            limits = ((2008.5, 2019.5), (0, 40)),
            )
        )
end
save(joinpath("figs", "investment.eps"), fig_plt_investment)

color_black = RGBAf(0 / 255, 0 / 255, 0 / 255, 1)
color_white = RGBAf(255 / 255, 255 / 255, 255 / 255, 1)
color_bealogoblue = RGBAf(0 / 255, 76 / 255, 151 / 255, 1)
color_bealb = RGBAf(195 / 255, 215 / 255, 238 / 255, 1)
color_bealogoorange = RGBAf(216 / 255, 96 / 255, 24 / 255, 1)
color_beamedorange = RGBAf(242 / 255, 169 / 255, 0 / 255, 1)
color_bealogogray = RGBAf(158 / 255, 162 / 255, 162 / 255, 1)
color_bealg = RGBAf(220 / 255, 222 / 255, 223 / 255, 1)
color_medblue = RGBAf(108 / 255, 172 / 255, 228 / 255, 1)
color_lo = RGBAf(255 / 255, 233 / 255, 195 / 255, 1)
color_medgray = RGBAf(193 / 255, 196 / 255, 197 / 255, 1)
color_dt = RGBAf(0 / 255, 125 / 255, 138 / 255, 1)
color_medteal = RGBAf(45 / 255, 204 / 255, 211 / 255, 1)
color_lt = RGBAf(177 / 255, 228 / 255, 227 / 255, 1)

COLORS = [
    color_bealogoblue,
    color_bealogoorange,
    color_bealogogray,
    color_bealb,
    color_beamedorange,
    color_medteal,
    color_bealg,
    color_medblue,
    color_lo,
    color_medgray,
    color_dt,
    color_lt,
    ]


# Software investment
response = request(
    "GET",
    URI(
        scheme = "https",
        host = "apps.bea.gov",
        path = "/api/data",
        query = append!(
            [
                "UserID" => ENV["API_BEA"],
                "method" => "GetData",
                "DatasetName" => "FixedAssets",
                "TableName" => "FAAt207",
                "Frequency" => "A",
                "Year" => join(2009:2019, ','),
                ],
            ),
        )
    )
json = JSON3.read(response.body)
tbl_software = DataFrame(elem for elem in json.BEAAPI.Results.Data if parse(Int, elem.LineNumber) ∈ 79:81)
select!(tbl_software, [:LineDescription, :TimePeriod, :DataValue])
transform!(
    tbl_software,
    :DataValue => ByRow(x -> parse(Float64, x)),
    renamecols = false,
    )
response = request(
    "GET",
    URI(
        scheme = "https",
        host = "apps.bea.gov",
        path = "/api/data",
        query = append!(
            [
                "UserID" => ENV["API_BEA"],
                "method" => "GetData",
                "DatasetName" => "NIPA",
                "TableName" => "T30905",
                "Frequency" => "A",
                "Year" => join(2009:2019, ','),
                ],
            ),
        )
    )
json = JSON3.read(response.body)
tbl_software_public = DataFrame(elem for elem in json.BEAAPI.Results.Data if parse(Int, elem.LineNumber) ∈ [23, 31, 39])
transform!(
    tbl_software_public,
    :LineNumber => ByRow(x -> begin
        if x == "23"
            "Defense"
        elseif x == "31"
            "Nondefense"
        elseif x == "39"
            "S&L"
        end
    end) => :LineDescription,
    :DataValue => ByRow(x -> parse(Int, replace(x, ',' => "")) / 1_000) => :DataValue,
    )
select!(tbl_software_public, [:LineDescription, :TimePeriod, :DataValue])

software_investment_data = vcat(tbl_software, tbl_software_public)

software_investment = data(software_investment_data) *
    mapping(
        :TimePeriod,
        :DataValue,
        color = :LineDescription => sorter(["Prepackaged", "Custom", "Own account", "Defense", "Nondefense", "S&L"]) => "",
        stack = :LineDescription => sorter(["Prepackaged", "Custom", "Own account", "Defense", "Nondefense", "S&L"])) *
    visual(BarPlot)
software_plt = with_theme(Theme(fontsize = 16)) do 
    draw(
        software_investment,
        axis = (
            xlabel = "Year",
            ylabel = "Billions of dollars",
            limits = (nothing, (0, 500)),
        ),
        palettes = (color = COLORS,),
        legend = (
                position = :top,
                titleposition = :top,
                framevisible = false,
                padding = 0,
            ),
        )
end
save(joinpath("figs", "software_investment.eps"), software_plt)

# Business Sector Software

software_nominals = vcat(
    transform(
        tbl_software,
        :TimePeriod .=> ByRow(x -> parse(Int, string(x))),
        renamecols = false,
        ),
    DataFrame(
        LineDescription = "OSS",
        TimePeriod = 2009:2019,
        DataValue = nominal ./ 1_000))

fig = data(software_nominals) *
    mapping(
        :TimePeriod => nonnumeric,
        :DataValue,
        color = :LineDescription => sorter(["Prepackaged", "Custom", "Own account", "OSS"]) => "",
        dodge = :LineDescription => sorter(["Prepackaged", "Custom", "Own account", "OSS"]),
        ) *
    visual(BarPlot)
comparison = with_theme(Theme(fontsize = 20)) do
    draw(
        fig,
        axis = (;
            xlabel = "Year",
            ylabel = "Investment in billions (\$)",
            limits = (nothing, (0, 200)),
            # xticks = string.(2009:2019),
            # yticks = 0:5:65,
            ),
        palettes = (
            color = COLORS[[1, 2, 3, 11]],
            ),
        legend = (
            position = :top,
            titleposition = :left,
            framevisible = false,
            padding = 0)
        )
end
save(joinpath("figs", "software_trends.eps"), comparison)

# For contributors
country_ctrs = DataFrame(
    execute(
        conn,
        """
        WITH a AS (
            SELECT
                country,
                count(*)
            FROM
                gh_cost.users_geo_101521
            GROUP BY
                country
        )
        SELECT
            country,
            count / 1000 count
        FROM
        a
        ORDER BY
            count DESC
        LIMIT
            10;
        """,
        not_null = true
        )
    )
country_ctrs_plt = data(country_ctrs) *
    mapping(
        :country => renamer(
            [
                "United States" => "USA",
                "China" => "CHN",
                "India" => "IND",
                "Germany" => "DEU",
                "United Kingdom" => "GBR",
                "Canada" => "CAN",
                "Brazil" => "BRA",
                "France" => "FRA",
                "Russia" => "RUS",
                "Japan" => "JPN",
            ]
        ),
        :count) *
    visual(
        BarPlot,
        color = RGBAf(0, 0, 0, 0.25),
        )
country_ctrs_plt_fig = with_theme(Theme(fontsize = 20)) do
    draw(
        country_ctrs_plt,
        axis = (;
            xlabel = "Country",
            ylabel = "Number of contributors (in thousands)",
            limits = (nothing, (0, 350)),
        )
    )
end
save(joinpath("figs", "country_ctrs.eps"), country_ctrs_plt_fig)
