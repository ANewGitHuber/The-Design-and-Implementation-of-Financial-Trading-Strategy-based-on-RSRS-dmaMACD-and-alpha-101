library(quantmod)

rm(list = ls())
price <- as.xts(read.zoo("10.csv",header=TRUE,sep=",",colClasses = c("Date", rep("numeric",5))))

n <- nrow(price)
m <- nrow(price)-1000

#pdf(file = "k.pdf")
chartSeries(price[c(m:n)],theme = chartTheme("white"),
            up.col = "red",dn.col = "green",name = "series_07",
            time.scale = 0.5,line.type = "l",bar.type = "ohlc",
            major.ticks='auto', minor.ticks=TRUE)
#dev.off()
chartSeries(price[c(m:n)],theme = chartTheme("white"),TA = "addSMA(n=10);addSMA(n=80);addMACD(type = 'EMA')")

