
### README - GitHub Network Data

The GitHub network data was constructed from the raw GitHub commits data (`gh.commits_raw`). The commits table contains all commit activity from GitHub data spanning 2008 (GitHub's start date) to the end of 2019. The `commits_raw` data contains all users that commit to OSI-approved licenses and the files in this folder take that commit data and projects the data into a format where all users (ctr1, ct2) that contribute to common repositories are connected by ties (i.e. listed next to each other in adjacent columns) that are both weighted and time-specific. The first step in this process is creating a year-by-year collaboration edgelist and then created 11 different tables for cumulative collaboration activity. 

GitHub file structure

├── `01_full-ctr-network-construction-dev.Rmd`
    ├── This details the network construction development process. This is redundant with the SQL files.
├── 02_sna_ctr_edgelist_xyx.sql 
    ├── This creates the edgelist for collaboration in a year-by-year fashion. 
├── 03_sna_ctr_nodelist_xyx.sql 
    ├── This pulls out all of the distinct nodes from the edgelist and creates a nodelist. 
├── 04_sna_ctr_edgelist_08.sql 
├── 03_sna_ctr_edgelist_08.sql
├── median property value 

    
PostgreSQL database structure 

├── built capital
    ├── housing
        ├── median property value 
        ├── built structure median age
        ├── percentage of single family housing 
        ├── percentage of vacant properties 
        ├── number of subsidized units (adj by population)
        ├── number of people in subsidized units (adj by population)
