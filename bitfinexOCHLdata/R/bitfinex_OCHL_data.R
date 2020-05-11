###########################################################
# Wellington Silva 05-09-2020                             #
# https://www.kaggle.com/gatunnopvp                       #
# https://github.com/WellingtonSilv                       #
# https://www.linkedin.com/in/wellington-silva-b430a1195/ #
###########################################################

#' @title A function that return OCHL data from bitfinex API
#'
#' @param symbol The currency symbol that needs to have a 't' before, example: tBTCUSD, tETHUSD, etc.
#' @param TimeFrame The period of the candles that can be: 1D, 1h, 30m, 15m and 5m.
#' @param window The number of candles to be downloaded per time, maximum 10000.
#' @param start_date A string with start date in UTC formart 1970-01-01 00:00:00
#' @param end_date A string with end date in UTC format 1970-01-01 00:00:00, only use if all_data == FALSE
#' @param sorted A integer that can be 1 or -1, 1 means old > new
#' @param all_data A logical TRUE or FALSE, TRUE download all historical OCHL data, FALSE download only the window
#' selected with start and end date parameters
#'
#' @return A DataFrame with open, close, high, low, volume and dates
#'
#' @export

bitfinex_OCHL_data <- function(symbol = 'tBTCUSD'
                               , TimeFrame = '1D'
                               , window = 10000
                               , start_date = '2013-07-02 00:00:00'
                               , end_date = '2020-05-07 00:00:00'
                               , sorted = 1
                               , all_data = T){
  library(httr)
  library(jsonlite)
  library(lubridate)

  # shift function
  shift <- function(x, n){
    c(x[-(seq(n))], rep(NA, n))
  }

  # converting string TimeFrame into minutes
  if(TimeFrame=='5m'){
    time_f <- 5
  }else if(TimeFrame=='15m'){
    time_f <- 15
  }else if(TimeFrame=='30m'){
    time_f <- 30
  }else if(TimeFrame=='1h'){
    time_f <- 60
  }else if(TimeFrame=='1D'){
    time_f <- 1440
  }

  # defining end of candles windows that will be requested
  window_end <- as.character(as.POSIXct(start_date
                                        , tz = 'UTC'
                                        , "%Y-%m-%d %H:%M:%S")+minutes(window*time_f))

  # requesting the last candle information
  url <- paste('https://api-pub.bitfinex.com/v2/candles/trade:',TimeFrame,':tBTCUSD/last/',sep = '')
  last_candle <- GET(url)
  data_json <- content(last_candle, "text")
  data_matrix <- fromJSON(data_json, flatten = TRUE)
  unix <- data_matrix[1]/1000 # dividing unix timestamp in milliseconds to be converted into UTC POSIXct below

  # calculating the total of candles to be requested using the loop
  if(all_data==T){
    total_candles <- as.numeric(difftime(as.character(as.POSIXct(unix, origin="1970-01-01 00:00:00"))
                                         , as.character(as.POSIXct(start_date,tz = 'UTC', '%Y-%m-%d %H:%M:%S'))
                                         , units = 'mins'))/time_f
  }else{
    total_candles <- as.numeric(difftime(as.character(as.POSIXct(end_date,tz = 'UTC', '%Y-%m-%d %H:%M:%S'))
                                         , as.character(as.POSIXct(start_date,tz = 'UTC', '%Y-%m-%d %H:%M:%S'))
                                         , units = 'mins'))/time_f
  }
  total_candles <- round(total_candles)

  # creating a data frame to to join the downloaded data
  data <- data.frame(0,0,0,0,0,start_date)
  names(data) <- c('open','close','high','low','vol','data')
  data$data <- as.character(data$data)
  data$data <- as.POSIXct(data$data,tz = 'UTC', '%Y-%m-%d %H:%M:%S')

  # calculating number of windows to be downloaded
  n_windows <- total_candles/(window)
  n_windows_r <- round(n_windows)
  if(n_windows_r<n_windows){
    n_windows_r <- n_windows_r+1
  }

  # loop to get and join OCHL data into the dataframe created before
  for(i in 1:n_windows_r){

    cat('downloading window',i,'...','\n')

    if(i==1){ # if is the first window

      start_date <- as.POSIXct(start_date,tz = 'UTC', '%Y-%m-%d %H:%M:%S')+minutes(time_f)
      window_end <- as.POSIXct(window_end,tz = 'UTC', '%Y-%m-%d %H:%M:%S')+minutes(time_f)

      if(all_data==T & total_candles>=window){
        # concatenating parameters into full url to use in GET function
        url <- paste("https://api-pub.bitfinex.com/v2/", "candles/trade:", TimeFrame, ':'
                      , symbol, '/hist', '?'
                      , 'limit=', window, '&'
                      , 'start=', as.numeric(start_date)*1000, '&'
                      , 'end=', as.numeric(window_end)*1000, '&'
                      , 'sort=', sorted, sep="")
      }

      if(all_data==T & total_candles<window){
        end_date <- as.POSIXct(end_date,tz = 'UTC', '%Y-%m-%d %H:%M:%S')+minutes(time_f)

        url <- paste("https://api-pub.bitfinex.com/v2/", "candles/trade:", TimeFrame, ':'
                     , symbol, '/hist', '?'
                     , 'limit=', total_candles, '&'
                     , 'start=', as.numeric(start_date)*1000, '&'
                     , 'end=', as.numeric(end_date)*1000, '&'
                     , 'sort=', sorted, sep="")
      }

      if(all_data==F & total_candles>=window){

        url <- paste("https://api-pub.bitfinex.com/v2/", "candles/trade:", TimeFrame, ':'
                      , symbol, '/hist', '?'
                      , 'limit=', window, '&'
                      , 'start=', as.numeric(start_date)*1000, '&'
                      , 'end=', as.numeric(window_end)*1000, '&'
                      , 'sort=', sorted, sep="")
      }

      if(all_data==F & total_candles<window){

        end_date <- as.POSIXct(end_date,tz = 'UTC', '%Y-%m-%d %H:%M:%S')+minutes(time_f)

        url <- paste("https://api-pub.bitfinex.com/v2/", "candles/trade:", TimeFrame, ':'
                      , symbol, '/hist', '?'
                      , 'limit=', total_candles, '&'
                      , 'start=', as.numeric(start_date)*1000, '&'
                      , 'end=', as.numeric(end_date)*1000, '&'
                      , 'sort=', sorted, sep="")
      }

    }else if(i>1 & i<n_windows_r){

      # jumping to next window to be downloaded
      start_date <- as.POSIXct(start_date,tz = 'UTC', '%Y-%m-%d %H:%M:%S')+minutes((window)*time_f)
      window_end <- as.POSIXct(window_end,tz = 'UTC', '%Y-%m-%d %H:%M:%S')+minutes((window)*time_f)

      url <- paste("https://api-pub.bitfinex.com/v2/"
                    , "candles/trade:", TimeFrame, ':'
                    , symbol, '/hist', '?'
                    , 'limit=',window , '&'
                    , 'start=', as.numeric(start_date)*1000, '&'
                    , 'end=', as.numeric(window_end)*1000, '&'
                    , 'sort=', sorted, sep="")
    }else{ # if is the last window

      start_date <- as.POSIXct(start_date,tz = 'UTC', '%Y-%m-%d %H:%M:%S')+minutes((window)*time_f)
      window_end <- as.POSIXct(window_end,tz = 'UTC', '%Y-%m-%d %H:%M:%S')+minutes((total_candles)*time_f)

      url <- paste("https://api-pub.bitfinex.com/v2/"
                    , "candles/trade:", TimeFrame, ':'
                    , symbol, '/hist', '?'
                    , 'limit=', total_candles, '&'
                    , 'start=', as.numeric(start_date)*1000, '&'
                    , 'end=', as.numeric(window_end)*1000, '&'
                    , 'sort=', sorted, sep="")
    }

    # getting the data from url created
    data_requested <- GET(url)

    # extracting JSON data from data_requested
    data_json <- content(data_requested, "text")

    # converting JSON into dataframe
    data_matrix <- fromJSON(data_json, flatten = TRUE)
    asset <- as.data.frame(data_matrix)
    names(asset) <- c('time','open','close','high','low','vol')

    # converting dates in string format to POSIXct format
    asset$data <- 'dates'
    for(j in 1:dim(asset)[1]){

      unix <- asset$time[j]/1000
      asset$data[j] <- paste(as.POSIXct(unix, origin="1970-01-01 00:00:00"))

      if(j==dim(asset)[1]){
        asset$time <- NULL
        asset$data <- as.POSIXct(asset$data, tz = 'UTC', '%Y-%m-%d %H:%M:%S')
      }
    } # end of loop

    # removing downloaded candles
    total_candles <- total_candles-window

    # joing downloaded data
    data <- rbind(data,asset)

    # shiftting dates if the TimeFrame selected is '1D'
    if(TimeFrame=='1D'){
      data$data <- as.character(data$data)
      data$data <- shift(data$data,1)
      data <- data[-dim(data)[1],]
    }

    if(i==n_windows_r){
      cat('download finished!','\n')
    }

    # sleep time to avoid rate limits
    Sys.sleep(2)
  } # end of loop

  # removing the fisrt row
  data <- data[2:dim(data)[1],]

  return(data)
}
