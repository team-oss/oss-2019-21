library(RPostgreSQL)
#conn <- dbConnect(drv = PostgreSQL(),
#                  host = "postgis_2",
#                  dbname = "sdad_data",
#                  user = Sys.getenv(x = "db_userid"),
#                  password = Sys.getenv(x = "db_pwd"))
#db_tbls <- dbReadTable(conn = conn,
#                       name = c(schema = "github", name = "commits_summary"))
#close(con = conn)

#```
#From Rivanna,
#```
#library(RPostgreSQL)
#conn <- dbConnect(drv = PostgreSQL(),
#                  host = "postgis1",
#                  dbname = "sdad",
#                  user = Sys.getenv(x = "db_userid"),
#                  password = Sys.getenv(x = "db_pwd"))
#db_tbls <- dbReadTable(conn = conn,
#                       name = c(schema = "github", name = "commits_summary"))
#close(con = conn)

conn <- dbConnect(drv = PostgreSQL(), dbname = "sdad_data",
                  host = "sdad.policy-analytics.net", port = 5436,
                  user = Sys.getenv("db_userid"), password = Sys.getenv("db_pwd"))

db_tbls <- dbReadTable(conn = conn,
                       name = c(schema = "github", name = "commits_summary"))

commit_country <- dbReadTable(conn = conn,
                              name = c(schema = "github", name = "forcost_bycc"))

repos <- dbReadTable(conn = conn,
                     name = c(schema = "github", name = "repos"))


dim(db_tbls)
#7799203

length(unique(db_tbls$slug))
#5188818 unique repos

db_tbls_rm70 <- db_tbls[which(db_tbls$year != "1970"),]
db_tbls_70 <- db_tbls[which(db_tbls$year == "1970"),]
length(unique(db_tbls_70$slug))


library(data.table)
#### COMMIT BY YEAR
dt <- data.table(db_tbls)

commit_loc_by_year <- dt[,.(sum(count_commits),sum(total_additions),sum(total_deletions)),year]
colnames(commit_loc_by_year) <- c("year","sum_commits","total_additions","total_deletions")
commit_loc_by_year <- setorder(commit_loc_by_year,year,na.last=TRUE)

#### NUMber of contributors by repo
#not possible with this data


### Group by repo

commit_loc_by_repo <- dt[,.(sum(count_commits),sum(total_additions),sum(total_deletions)),slug]
colnames(commit_loc_by_repo) <- c("slug","sum_commits","total_additions","total_deletions")
commit_loc_by_repo <- setorder(commit_loc_by_repo,-sum_commits,na.last=TRUE)

commit_loc_by_repo$sum_loc <- rowSums(commit_loc_by_repo[,3:4])
commit_loc_by_repo$sum_kloc <- (commit_loc_by_repo$sum_loc)/1000
commit_loc_by_repo$net_loc <- commit_loc_by_repo[,3]-commit_loc_by_repo[,4]
commit_loc_by_repo$net_kloc <- (commit_loc_by_repo$net_loc)/1000

#calculate_cost_from_kloc <- function(commit_loc_by_repo) {
#  costs_df <- commit_loc_by_repo %>%
#    dplyr::mutate(cost_18096.47 = round(18096.47 * 2.5 * (2.4 * (sum_kloc)^1.05)^0.38, 2),
#                  cost_19963.55 = round(19963.55 * 2.5 * (2.4 * (sum_kloc)^1.05)^0.38, 2)
#    ) %>%
#    select(-cost)
#  return(costs_df)
#}
#COST BASED ON Additions
commit_loc_by_repo[,cost_additions_18096.47 := round(18096.47 * 2.5 * (2.4 * (total_additions/1000)^1.05)^0.38,2)]
commit_loc_by_repo[,cost_additions_19963.55 := round(19963.55 * 2.5 * (2.4 * (total_additions/1000)^1.05)^0.38,2)]

#COST BASED ON Additions + Deletions
commit_loc_by_repo[,cost_sum_kloc_18096.47 := round(18096.47 * 2.5 * (2.4 * (sum_kloc)^1.05)^0.38,2)]
commit_loc_by_repo[,cost_sum_kloc_19963.55 := round(19963.55 * 2.5 * (2.4 * (sum_kloc)^1.05)^0.38,2)]

#COST BASED ON Additions - Deletions
commit_loc_by_repo[,cost_net_kloc_18096.47 := round(18096.47 * 2.5 * (2.4 * (net_kloc)^1.05)^0.38,2)]
commit_loc_by_repo[,cost_net_kloc_19963.55 := round(19963.55 * 2.5 * (2.4 * (net_kloc)^1.05)^0.38,2)]


## COUNTRIES

dt_commit_country <- data.table(commit_country)
loc_by_country <- dt_commit_country[,.(sum(additions),sum(deletions)),country_code]
colnames(loc_by_country) <- c("country_code","additions","deletions")