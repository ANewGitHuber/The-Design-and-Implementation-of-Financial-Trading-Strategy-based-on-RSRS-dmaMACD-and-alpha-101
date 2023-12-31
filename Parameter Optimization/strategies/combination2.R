maxRows <- 11000 # used to initialize a matrix to store closing prices
# set maxRows as the number of rows in data (it can be larger but should not be smaller)

getOrders <- function(store, newRowList, currentPos, info, params) {
  
  # Initializing
  allzero  <- rep(0,length(newRowList)) # used for initializing vectors
  
  # initialize store at the beginning
  if (is.null(store)) store <- initStore(newRowList,params$series)
  store <- updateStore(store, newRowList, params$series)
  
  # initialize market orders and limit orders
  marketOrders <- allzero
  
  limitOrders1=allzero;
  limitPrices1=allzero;
  limitOrders2=allzero;
  limitPrices2=allzero;
  

  # initialize dmaMACD strategy's market position
  dmaPos <- allzero
  #initial rsrs strategy position to be all 0
  rsrsPos <- -currentPos
  #rsrsPos2 <- store$rsrsPos
  a006Pos <- -currentPos
  
  
  
  #-----------------------------------logic for rsrs & alpha006-----------------------------------
  
  
  if(store$iter > params$rsrs_lookback_m + params$rsrs_lookback){
    
    #print(store$rsrsPos)

    for (i in 1:length(params$series)){

      #using open prices difference as the position normalization
      # CloseDiffs <- diff(store$cl)
      # absCloseDiffs <- matrix(abs(CloseDiffs),ncol = length(params$series))
      # avgAbsDiffs <- apply(absCloseDiffs,2,function(x) mean(x[x>0]))
      # largestAvgAbsDiffs <- max(avgAbsDiffs)
      # posnorm <- round(largestAvgAbsDiffs/avgAbsDiffs)
      
      clall <- matrix(store$cl,ncol = length(params$series))
      closeprice <- apply(clall,2, function(x) mean(x[x>0]))
      largestclose <- max(clall)
      #print(round(largestopen/openprice))
      posnorm <- round(largestclose/closeprice)
      
      estCostToBuy <- sum(posnorm * closeprice)
      targetspent_a <- 300000
      targetspent_r <- 50000
      multiplier_a <- targetspent_a/estCostToBuy
      multiplier_r <- targetspent_r/estCostToBuy

      #indicators
      HIGH = store$high[,i]
      LOW = store$low[,i]
      OPEN <- store$ope[,i]
      CLOSE <- store$cl[,i]
      VOLUME <- store$vol[,i]
      
      ##################################  Get Profit & Loss for Yesterday  #############################
      
      
      
      prev_close <- CLOSE[store$iter-2]
      cur_open <- OPEN[store$iter-1]
      next_open <- OPEN[store$iter]
      
      
      # run from day 2, where oldPos would always be 0, until penultimate day
      slippage <- abs(prev_close-next_open)*0.2
      
      # +/- (nextOp - curOp) * "held on cur" - slippage * "traded on cur"
      pnl_yesterday1 <- store$rsrsPos[params$series[i]] * (next_open - cur_open) - abs(store$rsrsPos[params$series[i]]) * slippage
      pnl_yesterday2 <- store$a006Pos[params$series[i]] * (next_open - cur_open) - abs(store$rsrsPos[params$series[i]]) * slippage
      
      pnl_yesterday <- pnl_yesterday1 + pnl_yesterday2
      #print(pnl_yesterday)
      
      
      ###################################################################################################
     

      # calculate Nth day's RSRS
      startIndex <- store$iter - params$rsrs_lookback #params$lookback=10, start from 301th day
      rsrs_n <- Cal_RSRS(HIGH, LOW, startIndex,store$iter)
      #print(rsrs_n)

      # calculate previous M days RSRS
      startIndex_m <- store$iter - params$rsrs_lookback_m #start from 11th day
      rsrs_m <- Cal_RSRS_M(HIGH, LOW, startIndex_m, params$rsrs_lookback, store$iter)

      #z-score rsrs
      rsrs_z <- (rsrs_n - mean(rsrs_m))/sd(rsrs_m)
      
      #ATR
      ATR <- as.numeric(Cal_ATR(HIGH, LOW, CLOSE, startIndex, params$rsrs_lookback, store$iter))
     # print(ATR)
      stop <- ATR*0.8
      op <- OPEN[store$iter]
      mean_p <- (HIGH[store$iter]+LOW[store$iter])/2
      
      #Now alpha006

      if(store$iter<=obday){
        VOLUMELIST <- VOLUME[0:store$iter]
        CLOSELIST <- CLOSE[0:store$iter]
      }

      #After the specified days, store the most recent n days' data
      #n is the observed day and is passed in through parameter "obday"
      else if(store$iter>obday){
        VOLUMELIST <- VOLUME[as.numeric(store$iter-obday):store$iter]
        CLOSELIST <- CLOSE[as.numeric(store$iter-obday):store$iter]
      }

      #Apply Alpha006 equation
      #Get Everyday's new alpha rate
      alpha006 = -1*cor(as.vector(CLOSELIST), as.vector(VOLUMELIST), use = "everything", method="pearson")
      #correlation value larger - tongzhangtongdie (we do not want)
      #with (-1): Alpha006's value larger - means Liangjiabeili larger - means we should buy
      #print(paste("alpha006 =",alpha006))
      
      if (store$iter > 10){
        OPENLIST <- OPEN[0:store$iter]
        CLOSELIST <- CLOSE[0:store$iter]
        amplitude <- CLOSE[store$iter]-OPEN[store$iter]
        alpha018vector = -1*rank(runSD(abs(CLOSELIST-OPENLIST), n=5) + amplitude + runCor(CLOSELIST, OPENLIST, n = 10))
        
        #Find the current days' alpha 018 value
        alpha018 <- alpha018vector[store$iter]
        rank018 <- alpha018/store$iter
      }
      
      #Set Position
      if (rsrs_z < 0.7){
        
        rsrsPos[params$series[i]] <- -round(rsrs_n * (posnorm[i])) * multiplier_r
        
        #rsrs Stop loss
        if(as.numeric(op) >= as.numeric(mean_p) - as.numeric(stop)){
          limitOrders1[i] <- rsrsPos[params$series[i]]
          limitPrices1[i] <- mean_p + stop
        }
      }

      else if (rsrs_z > 0.7){
        
        rsrsPos[params$series[i]] <- round(rsrs_n * (posnorm[i]))* multiplier_r
        
        #rsrs Stop loss
        if(as.numeric(op) <= as.numeric(mean_p) - as.numeric(stop)){
          limitOrders2[i] <- -rsrsPos[params$series[i]]
          limitPrices2[i] <- mean_p - stop
        }
        
        if (alpha006*100 > thr006){
          if(rank018 <= 0.2){
            
            a006Pos[params$series[i]] <- round(1+alpha006) * posnorm[i]*multiplier_a
          }
          else if(rank018 <= 0.5 && rank018 > 0.2 ){
            a006Pos[params$series[i]] <- round(1+alpha006) * posnorm[i]*(multiplier_a/2)
            
          }
          else{
            a006Pos[params$series[i]] <- round(1+alpha006) * posnorm[i] *(multiplier_a/4)
            
          }
        }
      }
      
      else{
          rsrsPos[params$series[i]] <- 0
          a006Pos[params$series[i]] <- 0
      }
      
      ##################################### stop loss ####################################################
      if (pnl_yesterday<0){
        rsrsPos <- rsrsPos/2
        a006Pos <- a006Pos/2
      }
      
      ####################################################################################################
    }
  }

  #-----------------------------------logic for dmaMACD-----------------------------------
    
  if (store$iter > params$dmalookbacks$long && store$iter > params$macdlookback) {


    startIndexma <-  store$iter - params$dmalookback$long
    startIndexmacd <-  store$iter - params$macdlookback
    startIndexkdj <- store$iter - params$kdjlookback

    for (i in 1:length(params$series)) {
      
      #indicators
      HIGH = store$high[,i]
      LOW = store$low[,i]
      OPEN <- store$ope[,i]
      CLOSE <- store$cl[,i]
      VOLUME <- store$vol[,i]
      
      ##################################  Get Profit & Loss for Yesterday  #############################
      
      
      
      prev_close <- CLOSE[store$iter-2]
      cur_open <- OPEN[store$iter-1]
      next_open <- OPEN[store$iter]
      
      
      # run from day 2, where oldPos would always be 0, until penultimate day
      slippage <- abs(prev_close-next_open)*0.2
      
      # +/- (nextOp - curOp) * "held on cur" - slippage * "traded on cur"
      pnl_yesterday3 <- store$dmaPos[params$series[i]] * (next_open - cur_open) - abs(store$dmaPos[params$series[i]]) * slippage
      #print(pnl_yesterday)
      
      
      ###################################################################################################


      closeP <- as.vector(newRowList[[params$series[i]]]$Close)
      short_ma <- last(SMA(store$cl[startIndexma:store$iter,i],n=params$dmalookbacks$short))
      long_ma <- last(SMA(store$cl[startIndexma:store$iter,i],n=params$dmalookbacks$long))
      macd <- as.data.frame(last(MACD(store$cl[startIndexmacd:store$iter,i],
                                      nFast=params$macdFast, nSlow=params$macdSlow,
                                      maType=params$macdMa, percent=TRUE)))
      KDJ<- as.data.frame(last(stoch(store$cl[startIndexkdj:store$iter,i],nFastK = params$nFastK, 
                                     nFastD = params$nFastD,
                                     nSlowD = params$nSlowD, bounded = TRUE,smooth = 1)))
      Kline <- KDJ$fastK * 100
      #using maximum close price and mean(close) to set position normalization
      clall <- matrix(store$cl,ncol = length(params$series))
      closeprice <- apply(clall,2, function(x) mean(x[x>0]))
      largestclose <- max(clall)
      #print(round(largestopen/openprice))
      posnorm1 <- round(largestclose/closeprice)
      estCostToBuy <- sum(posnorm1 * closeprice)
      targetspent <- 450000
      multiplier_d <- targetspent / estCostToBuy
      #print(multiplier_d)
      #print(dmaPos)
      #print(round(largestAvgAbsDiffs/avgAbsDiffs))
      #when there is a cross in double moving average and macd indicators
      #it is a clear entry point and it also implies the future up-ward trending

      if (last((SMA(store$cl[startIndexma:(store$iter-1),i],n=params$dmalookbacks$short)))
          <
          last((SMA(store$cl[startIndexma:(store$iter-1),i],n=params$dmalookbacks$long)))
          &&short_ma >= long_ma
          && macd$macd >macd$signal ) {

        if(rank018 <= 0.2){
          
          dmaPos[params$series[i]] <-  abs(short_ma - long_ma)*multiplier_d/long_ma*(posnorm1[i])*100
        }
        else if(rank018 <= 0.5 && rank018 > 0.2 ){
          dmaPos[params$series[i]] <-  (abs(short_ma - long_ma)/long_ma)*100*posnorm1[i]*(multiplier_d/2)
          
        }
        else{
          dmaPos[params$series[i]] <-  (abs(short_ma - long_ma)/long_ma)*100*posnorm1[i]*(multiplier_d/4)
          
        }
        
        if(Kline<50 && closeP < short_ma){
          limitOrders1[i] <- -dmaPos[params$series[i]]
          limitPrices1[i] <- short_ma * (1 - 0.05)
        }

      }

      #when there is a cross in double moving average and macd indicators
      #it is a clear exit point and it also implies the future down-ward trending
      # last((SMA(store$cl[startIndexma:store$iter-1,i],n=params$dmalookbacks$short)))
      # >
      #   last((SMA(store$cl[startIndexma:store$iter-1,i],n=params$dmalookbacks$long)))
      # &&
      else if (last((SMA(store$cl[startIndexma:store$iter-1,i],n=params$dmalookbacks$short)))
               >
               last((SMA(store$cl[startIndexma:store$iter-1,i],n=params$dmalookbacks$long)))
               &&short_ma <= long_ma
               && macd$macd < macd$signal
      ) {

        dmaPos[params$series[i]] <- -abs(short_ma - long_ma)/long_ma*(posnorm1[i])*100*multiplier_d
        if(Kline>50 && closeP > short_ma){
          limitOrders1[i] <- dmaPos[params$series[i]]
          limitPrices1[i] <- short_ma * (1 + 0.05)
        }
      }
      else{
        dmaPos[params$series[i]] <- 0
      }
      
      
      ##################################### stop loss ####################################################
      if (pnl_yesterday3<0){
        dmaPos <- dmaPos/2
      }
      
      ####################################################################################################
      
    }

  }
  #print(dmaPos)
  
  # Store all the values
  store <- updateDmaPos(store, dmaPos)
  store <- updateRsrsPos(store, rsrsPos)
  store <- updateAlpha006Pos(store, a006Pos)
  
  #print(store$rsrsPos)

  marketOrders <- marketOrders + rsrsPos + dmaPos + a006Pos
  
  return(list(store=store,marketOrders=marketOrders,
              limitOrders1=limitOrders1,limitPrices1=limitPrices1,
              limitOrders2=limitOrders2,limitPrices2=limitPrices2))
}


#---------------------------------------------------------------Functions---------------------------------------------------------------

#Functions of rsrs strategy;
Cal_RSRS <- function(HIGH,LOW,  startIndex, iter)
  for (j in startIndex:iter){
    HighList <- HIGH[startIndex:(iter-1)]
    LowList <- LOW[startIndex:(iter-1)]
    #OLS linear regression
    fit=lm(HighList~LowList)
    nrsrs <- as.numeric(fit$coefficients[2])
    return(nrsrs)
  }

Cal_RSRS_M <- function(HIGH,LOW, startIndex_m,lookback,iter){
  N = startIndex_m
  mrsrs = c()
  for (i in N:iter){ #定义i循环
    
    HighList <- HIGH[(i-lookback):i]
    LowList <- LOW[(i-lookback):i]
    #OLS linear regression
    fit=lm(HighList~LowList)
    #store all rsrs values as a vector
    mrsrs=c(mrsrs,as.numeric(fit$coefficients[2]))
  }
  return(mrsrs)
}

Cal_ATR <- function(HIGH,LOW,CLOSE,startIndex,lookback,iter){
  nTR <- 0
  for( i in startIndex+1:iter){
    #52~69
    TR <- max((HIGH[i]-LOW[i]), abs(HIGH[i]-CLOSE[i-1]), abs(CLOSE[i-1]-LOW[i]))
    nTR <- nTR + TR 
  } 
  ATR <- nTR/lookback
  return(ATR)
}
#---------------------------------------------------------------


###############################################################################
# All the subsequent functions were designed to simplify and
# improve the readaility of getNewPos();
#
# While not required, this type of function-based approach is advisable
# and these functions will likely have analogues in your strategies
###############################################################################

#-------------------------------------------
#dmaPos records the position of dmaMACD strategy, which will be used for the strategy's stop loss
updateDmaPos <- function(store, dmaPos) {
  store$dmaPos <- dmaPos
  return(store)
}
#rsrsPos records the position of rsrs strategy, which will be used for the strategy's stop loss
updateRsrsPos <- function(store, rsrsPos) {
  store$rsrsPos <- rsrsPos
  return(store)
}
#a006Pos records the pos of Alpha006 strategy
updateAlpha006Pos <- function(store, a006Pos) {
  store$a006Pos <- a006Pos
  return(store)
}
#-------------------------------------------


#-------------------------------------------
# functions for managing the Close
initClStore  <- function(newRowList,series) {
  clStore <- matrix(0,nrow=maxRows,ncol=length(series))
  return(clStore)
}
updateClStore <- function(clStore, newRowList, series, iter) {
  for (i in 1:length(series))
    clStore[iter,i] <- as.numeric(newRowList[[series[i]]]$Close)
  return(clStore)
}

# functions for managing the High
initHigh  <- function(newRowList,series) {
  high <- matrix(0,nrow=maxRows,ncol=length(series))
  return(high)
}
updateHigh <- function(high, newRowList, series, iter) {
  for (i in 1:length(series))
    high[iter,i] <- as.numeric(newRowList[[series[i]]]$High)
  return(high)
}

#functions for managing the Low
initLow  <- function(newRowList,series) {
  low <- matrix(0,nrow=maxRows,ncol=length(series))
  return(low)
}
updateLow <- function(low, newRowList, series, iter) {
  for (i in 1:length(series))
    low[iter,i] <- as.numeric(newRowList[[series[i]]]$Low)
  return(low)
}

#functions for managing the Volume
initVolStore  <- function(newRowList,series) {
  volStore <- matrix(0,nrow=maxRows,ncol=length(series))
  return(volStore)
}
updateVolStore <- function(volStore, newRowList, series, iter) {
  for (i in 1:length(series))
    volStore[iter,i] <- as.numeric(newRowList[[series[i]]]$Volume)
  return(volStore)
}

#functions for managing open prices
initOpeStore  <- function(newRowList,series) {
  opeStore <- matrix(0,nrow=maxRows,ncol=length(series))
  return(opeStore)
}
updateOpeStore <- function(opeStore, newRowList, series, iter) {
  for (i in 1:length(series))
    opeStore[iter,i] <- as.numeric(newRowList[[series[i]]]$Open)
  return(opeStore)
}

#-------------------------------------------
initStore <- function(newRowList,series) {
  return(list(iter=0,cl=initClStore(newRowList,series),
              vol=initVolStore(newRowList,series),
              high=initHigh(newRowList,series),
              low=initLow(newRowList,series),
              ope=initOpeStore(newRowList,series),
              dmaPos=rep(0,ncol= length(params$series)),
              rsrsPos=rep(0,ncol= length(params$series)),
              a006Pos=rep(0,ncol= length(params$series))
             ))
}

updateStore <- function(store, newRowList, series, action) {
  store$iter <- store$iter + 1
  store$cl <- updateClStore(store$cl,newRowList,series,store$iter)
  store$ope <- updateOpeStore(store$ope,newRowList,series,store$iter)
  store$vol <- updateVolStore(store$vol,newRowList,series,store$iter)
  store$high <- updateHigh(store$high,newRowList,series,store$iter)
  store$low <- updateLow(store$low,newRowList,series,store$iter)
  return(store)
}
