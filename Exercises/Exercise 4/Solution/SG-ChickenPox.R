### Call for libraries ###
library(tseries)
library(forecast)
library(cluster)
### In case it is your first time in R, install them as: ###
#install.packages('tseries')
#install.packages('forecast')
#install.packages('cluster')

# Set fix random generator numbers 
set.seed(0)

##############################
# CHOOSE SIZE OF TRAIN SET ###
##############################

TrainSetSize <- 0.85 # Do not touch this

#####################
### READ DATA SET ###
#####################

DataSet1_Chickenpox   <- na.omit(read.csv('monthly-reported-number-of-chick.csv',sep=';',dec='.')$Monthly.reported.number.of.chickenpox..New.York.city..1931.1972)

TrainSetSize <- 0.85

#################################
### DIVIDE SETS AND PLOT THEM ###
#################################

# Choose data set you want to work with:
DataSet <- DataSet1_Chickenpox

# Divide traning and test set:
smp_size <- floor(TrainSetSize * length(DataSet))
train_ind <- c(1:smp_size)
train <- DataSet[train_ind]
test <- DataSet[-train_ind]
# Plot data:
plot(train,type = 'l',col='darkorange',lwd=2,main = '',xlab = 'Time []',ylab='',xlim=c(1,length(DataSet)),ylim = c(min(DataSet),max(DataSet)))
lines(c((length(train)+1):(length(DataSet))),test,lwd=2,col='black')
abline(v=length(train),col='grey')
legend('topleft',legend=c('Training Set','Test Set'),col=c('darkorange','black'),lwd=c(2,2))

##############################
### TIME SERIES ANALYSIS ######
##############################

# Plot ACF and PACF to check stationarity and correlations:
acf(train,main='ACF for Data',length(train)/2)
pacf(train,main='PACF for Data',length(train)/2)

##
# ACF looks highly seasonal with peaks that increase and decrease very fast, this is a clear seasonality every 12 months.
# This ups and downs look a high seasonal behaviour in the data 
# We also see in the plot (not the ACF) variability in the peaks, we can remove this peaks by using the log transfrom.
# Variability in the peaks imply that the mean will move also, so we will try to differentiate with lag 12 
## 


plot(log(train),type = 'l',col='darkorange',lwd=2,main = '',xlab = 'Time [months]',ylab='',xlim=c(1,length(DataSet)),ylim = c(min(log(DataSet)),max(log(DataSet))))
lines(c((length(train)+1):(length(DataSet))),log(test),lwd=2,col='black')
abline(v=length(train),col='grey')
legend('topleft',legend=c('Training Set','Test Set'),col=c('darkorange','black'),lwd=c(2,2))

# Now you see how applying the log transfrom, the peaks have drecreased.

# Apply transformations if required:
transformdata  <- diff(diff(log(train),12),1)

acf(transformdata,main='ACF for Data',length(train)/4)
pacf(transformdata,main='PACF for Data',length(train)/4)

##
# The ACF and PACF dont dont say that much, the only thing we know, is that S=12, d=1 and D=1. I would start tuning parameters p,q,P and Q. 
# After tuning this parameters and calibrate the model we see that for p=1, q=1, P=0, Q=1. The residuals of the normal distribution behave as normal radom noise and the predictions look quite accurate. 
##

# Create ARIMA order=(p,d,q) or SARIMA order=(p,d,q)x(P,D,Q)S:
p = 1# AR(p)
d = 1# differentiate order
q = 1# MA(q)
# Seasonal 
S = 12# Seasonality  
P = 0# AR(P) Seasonal
D = 1# differentiate order Seasonal
Q = 1# MA(Q) Seasonal


TS_Model <- arima(log(train),order = c(p,d,q), seasonal = list(order = c(P,D,Q), period = S))
# Check residuals of the model:
hist(TS_Model$residuals,prob = T,breaks = 20,col='deepskyblue1',main='Histogram residuals')
curve(dnorm(x, mean(TS_Model$residuals), sd(TS_Model$residuals)), add=TRUE, col="red", lwd=2)

qqnorm(TS_Model$residuals,main='Q-Q plot residuals')
qqline(TS_Model$residuals)

plot(c(fitted(TS_Model)),c(TS_Model$residuals),pch=20,col='red',xlab = 'Fitted Values',ylab='Residuals',main='Residual vs Fitted residuals')
abline(h=0)

acf(TS_Model$residuals,length(train)/2,main='ACF for residuals')


##############################################
### LETS MAKE PREDICTIONS AND PLOT THEM ######
##############################################

# Predict n.ahead steps:
Predictions <- predict(TS_Model, n.ahead = length(test))

##
# Transfrom this predictions to the exponetial (because we were predicting using the log transform)
##

# Plot predictions:
plot(train,type = 'l',col='darkorange',lwd=2,main = 'Fill Data',xlab = 'Time',ylab='Data',xlim=c(1,length(DataSet)),ylim = c(0,max(DataSet)))
lines(c((length(train)+1):(length(DataSet))),test,lwd=2,col='gray60')
lines(c((length(train)+1):(length(DataSet))),exp(Predictions$pred),lwd=2,col='darkviolet')
lines(c((length(train)+1):(length(DataSet))),exp(Predictions$pred+Predictions$se),lwd=2,lty=2,col='darkviolet')
lines(c((length(train)+1):(length(DataSet))),exp(Predictions$pred-Predictions$se),lwd=2,lty=2,col='darkviolet')
abline(v=length(train),col='grey')
legend('topleft',legend=c('Past observations','Real Observations','Mean Forecast','95% Conf. Intervals Forecast'),col=c('darkorange','gray60','darkviolet','darkviolet'),lwd=c(2,2,2,2),lty=c(1,1,1,2))

###
# Let us make scenarios 
###

Steps <- length(test) # predict the next periods
Scen <- 1000 # initial number of scenarios
RedScen <- 10 # Reduce number of scenarios
# Data structure to store the scenarios
Scenarios <- matrix(NA,nrow =Steps ,ncol =Scen )
# Loop over scenarios and simulate with the arima model a prediction for the next 24 hours
for(w in 1:Scen){
  Scenarios[,w]  <- simulate(TS_Model, nsim=Steps, future=TRUE, seed=w)
}
# Transform the scenarios and plot them --> we need to reverse the log transformation
TransformScenarios <- exp(Scenarios)

plot(train,type = 'l',col='darkorange',lwd=1,main = '',xlab = 'Time [months]',ylab='Number of passengers (thousands)',xlim=c(1,length(DataSet)),ylim = c(min(TransformScenarios),max(TransformScenarios)))
points(train,col='darkorange',pch=20)
for(w in 1:Scen){lines(c((length(train)+1):(length(DataSet))),TransformScenarios[,w],col='grey',lwd=0.5)}
lines(c((length(train)+1):(length(DataSet))),test,lwd=1,col='black')
points(c((length(train)+1):(length(DataSet))),test,pch=20,col='black')
abline(v=length(train),col='grey')
legend('topleft',legend=c('Past observations','Actual Observations','Scenarios'),col=c('darkorange','black','grey'),lwd=c(1,1,1),lty=c(1,1,1))
# Reduce scenarios using Partitions around medoids
Scenarios_pam <- pam(t(TransformScenarios),RedScen)
Scenarios_pam$medoids
plot(train,type = 'l',col='darkorange',lwd=1,main = '',xlab = 'Time [months]',ylab='Number of passengers (thousands)',xlim=c(1,length(DataSet)),ylim = c(min(Scenarios_pam$medoids),max(c(train,Scenarios_pam$medoids))))
points(train,col='darkorange',pch=20)
for(w in 1:RedScen){lines(c((length(train)+1):(length(DataSet))),Scenarios_pam$medoids[w,],col='grey',lwd=0.5)}
lines(c((length(train)+1):(length(DataSet))),test,lwd=1,col='black')
points(c((length(train)+1):(length(DataSet))),test,pch=20,col='black')
abline(v=length(train),col='grey')
legend('topleft',legend=c('Past observations','Actual Observations','Scenarios'),col=c('darkorange','black','grey'),lwd=c(1,1,1),lty=c(1,1,1))
# Probability Distribution for reduced number of scenarios
Probability <- 1/length(1:Scen)
Reduce_prob <- c() 
for (i in 1:RedScen) {
  Reduce_prob[i] <- Probability *length( Scenarios_pam$clustering[ Scenarios_pam$clustering==i])
}
# Store these two values for later use
ChickenPox_Scenarios  <- round(t(Scenarios_pam$medoids)*Scen,0)
Probability_Scenarios <- Reduce_prob

ChickenPox_CSV <- ChickenPox_Scenarios
colnames(ChickenPox_CSV) <- c(',s1',paste0('s',2:RedScen))
rownames(ChickenPox_CSV) <- paste0('t',1:length(test))

Probability_CSV <- matrix(Probability_Scenarios,RedScen,1)
rownames(Probability_CSV) <- paste0('s',1:RedScen)

write.table(ChickenPox_CSV,file =  'Scenarios-ChickenPox.csv', sep=",",  dec=".",row.names=TRUE,col.names=TRUE,quote=FALSE)
write.table(Probability_CSV,file =  'Probability-ChickenPox.csv', sep=",",  dec=".",row.names=TRUE,col.names=FALSE,quote=FALSE)



