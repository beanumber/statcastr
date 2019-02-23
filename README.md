
[![Travis build status](https://travis-ci.org/beanumber/statcastr.svg?branch=master)](https://travis-ci.org/beanumber/statcastr)

<!-- README.md is generated from README.Rmd. Please edit that file -->
statcastr
=========

The goal of `statcastr` is to make building a Statcast database easy.

Installation
------------

You can install the released version of `statcastr` from [GitHub](https://www.github.com/beanumber/statcastr) with:

``` r
devtools::install_github("beanumber/statcastr")
```

Example
-------

For example, once we set up a database connection...

``` r
library(tidyverse)
library(statcastr)
db <- src_mysql_cnf(dbname = "statcastr")
sc <- etl("statcastr", db = db, dir = "~/dumps/statcastr")
```

...we can download the entire 2017 season's worth of data.

``` r
sc %>%
  etl_extract(year = 2017, month = 4:9) %>%
  etl_transform() %>%
  etl_load(tablenames = "statcast")
```

We now have a database containing 700,000 records.

``` r
sc %>%
  tbl("statcast") %>%
  mutate(the_month = MONTH(STR_TO_DATE(game_date, "%Y-%m-%d"))) %>%
  group_by(the_month) %>%
  summarize(num_records = n(), 
            num_games = n_distinct(game_pk),
            num_teams = n_distinct(home_team), 
            barrel_pct = sum(barrel) / sum(barrel != "NA"))
#> # Source:   lazy query [?? x 5]
#> # Database: mysql 5.7.25-0ubuntu0.16.04.2 [root@127.0.0.1:/statcastr]
#>   the_month num_records num_games num_teams barrel_pct
#>       <dbl>       <dbl>     <dbl>     <dbl>      <dbl>
#> 1         4      121273       369        30     0.0569
#> 2         5      132850       421        30     0.0556
#> 3         6      131858       408        30     0.0537
#> 4         7      125257       376        30     0.0492
#> 5         8      137587       425        30     0.0505
#> 6         9      136514       416        30     0.0497
```
