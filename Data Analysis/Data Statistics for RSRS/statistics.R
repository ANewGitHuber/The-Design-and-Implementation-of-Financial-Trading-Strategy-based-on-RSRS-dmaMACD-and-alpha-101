data=read.csv("01.csv",header=TRUE, stringsAsFactors=FALSE)


# define the rolling window size for beta calculation
N=18           
# initialize an empty vector to store the beta values           
nbeta=c()                  

nrow(data)   

# This loop calculates rolling beta values
for (i in N:nrow(data)) {
   # select a rolling window of size 18
  newdata=data[(i-17):i,] 
   # fit a linear regression model
  fit=lm(High~Low,data=newdata)  
  # store the beta value in the 'nbeta' vector
  nbeta=c(nbeta,as.numeric(fit$coefficients[2]))  
}

print(paste("Mean rsrs_n", mean(na.omit(nbeta)))) 
print(paste("Standard Deviation rsrs_n",sd(na.omit(nbeta))))  

hist(nbeta,breaks =seq(from=-5,to=5,by=0.01))  



# initialize an empty vector to store the z-score values
nrsrs_z=c()                

# This loop calculates rolling z-score values
for (j in (N+50):nrow(data)){
  # select the previous 50 beta values
  rsrs_m <- nbeta[c(j-50:j)]  
   # select the current beta value
  rsrs_n <- nbeta[c(j)]     
   # calculate the z-score 
  rsrs_z <- (rsrs_n - mean(rsrs_m))/sd(rsrs_m)  
  # store the z-score value in the 'nrsrs_z' vector
  nrsrs_z = c(nrsrs_z, as.numeric(rsrs_z))  
}

print(paste("Mean nrsrs_z", mean(na.omit(nrsrs_z))))  
print(paste("Standard Deviation nrsrs_z",sd(na.omit(nrsrs_z)))) 

hist(nrsrs_z,breaks =seq(from=-10,to=10,by=0.1))  

