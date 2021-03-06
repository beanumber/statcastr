globalVariables(c("month_begin", "sz_top", "sz_bot", "game_date"))

#' Scrape Statcast data
#' @param obj ETL object
#' @param years A numeric vector of years
#' @param months A numeric vector of months
#' @param ... arguments passed to \code{\link[baseballr]{scrape_statcast_savant_batter_all}}
#' @import etl
#' @importFrom dplyr %>%
#' @importFrom baseballr scrape_statcast_savant_batter_all
#' @export
#' @examples
#'
#' sc <- etl("statcastr")
#' \dontrun{
#' sc %>%
#'   etl_extract() %>%
#'   etl_transform() %>%
#'   etl_load(tablenames = "statcast")
#' }

etl_extract.etl_statcastr <- function(obj, years = 2019, months = 6, ...) {
  dates <- etl::valid_year_month(years, months, begin = "2015-03-01")

  mapply(FUN = scrape_statcast_month, dates$year, dates$month, SIMPLIFY = FALSE,
         MoreArgs = list(obj = obj))

  invisible(obj)
}

scrape_statcast_month <- function(obj, year, month) {

  dates <- etl::valid_year_month(year, month, begin = "2015-03-01") %>%
    dplyr::mutate(month_q1 = month_begin + lubridate::days(7),
                  month_middle = month_begin + lubridate::days(14),
                  month_q3 = month_begin + lubridate::days(21),
                  filename = paste("statcast", year,
                                   stringr::str_pad(month, width = 2, side = "left", pad = 0),
                                   "all.csv", sep = "_"))

  w <- mapply(FUN = baseballr::scrape_statcast_savant_batter_all,
              as.character(dates$month_begin),
              as.character(dates$month_q1),
              SIMPLIFY = FALSE) %>%
    dplyr::bind_rows()

  x <- mapply(FUN = baseballr::scrape_statcast_savant_batter_all,
              as.character(dates$month_q1),
              as.character(dates$month_middle),
              SIMPLIFY = FALSE) %>%
    dplyr::bind_rows()

  y <- mapply(FUN = baseballr::scrape_statcast_savant_batter_all,
              as.character(dates$month_middle),
              as.character(dates$month_q3),
              SIMPLIFY = FALSE) %>%
    dplyr::bind_rows()

  z <- mapply(FUN = baseballr::scrape_statcast_savant_batter_all,
              as.character(dates$month_q3),
              as.character(dates$month_end),
              SIMPLIFY = FALSE) %>%
    dplyr::bind_rows()

  data <- list(w, x, y, z)
  data <- lapply(data, dplyr::mutate,
                 sz_top = as.numeric(sz_top),
                 sz_bot = as.numeric(sz_bot))

  out <- data %>%
    dplyr::bind_rows() %>%
    dplyr::arrange(game_date)

  readr::write_csv(out, path = file.path(attr(obj, "raw"), dates$filename), na = "\\N")
}


#' @rdname etl_extract.etl_statcastr
#' @export

etl_load.etl_statcastr <- function(obj, years = 2019, months = 6, ...) {
  dates <- etl::valid_year_month(years, months, begin = "2015-03-01")

  src <- etl::match_files_by_year_months(
    fs::dir_ls(attr(obj, "load_dir")),
    pattern = "statcast_%Y_%m_all.csv",
    years = unique(dates$year),
    months = unique(dates$month)
  )

  etl::smart_upload(obj, src = src, tablenames = "statcast", ...)
  invisible(obj)
}
