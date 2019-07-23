
[![Travis build
status](https://travis-ci.org/beanumber/statcastr.svg?branch=master)](https://travis-ci.org/beanumber/statcastr)

<!-- README.md is generated from README.Rmd. Please edit that file -->

# statcastr

The goal of `statcastr` is to make building a Statcast database easy.

## Installation

You can install the released version of `statcastr` from
[GitHub](https://www.github.com/beanumber/statcastr) with:

``` r
devtools::install_github("beanumber/statcastr")
```

## Example

For example, once we set up a database connection…

``` r
library(tidyverse)
library(statcastr)
db <- src_mysql_cnf(dbname = "statcast")
sc <- etl("statcastr", db = db, dir = "~/Data/statcastr")
```

…we can download the entire 2019 season’s worth of data.

``` r
sc %>%
  etl_extract(year = 2019, month = 4:7) %>%
  etl_transform() %>%
  etl_load()
```

We now have a database containing 700,000 records.

``` r
sc %>%
  tbl("statcast") %>%
  mutate(the_date = STR_TO_DATE(game_date, "%Y-%m-%d"), 
         the_year = YEAR(the_date), 
         the_month = MONTH(the_date)) %>%
  filter(the_year == 2019) %>%
  group_by(the_month) %>%
  summarize(
    num_records = n(), 
    num_games = n_distinct(game_pk),
    num_teams = n_distinct(home_team), 
    barrel_pct = sum(barrel) / sum(barrel != "NA")
  )
#> # Source:   lazy query [?? x 5]
#> # Database: mysql 5.7.26-0ubuntu0.18.04.1 [bbaumer@127.0.0.1:/statcast]
#>   the_month num_records num_games num_teams barrel_pct
#>       <dbl>       <dbl>     <dbl>     <dbl>      <dbl>
#> 1         4       97365       295        30     0.0678
#> 2         5      135245       414        30     0.0629
#> 3         6      135545       404        30     0.0605
#> 4         7       27033        90        20     0.0643
```
