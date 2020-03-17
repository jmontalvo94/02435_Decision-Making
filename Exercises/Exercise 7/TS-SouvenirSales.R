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

DataSet3_Souvenirs       <- read.csv('sell-souvenirs-USmonthly.csv',sep=';',dec='.',header = F)$V1


#################################
### DIVIDE SETS AND PLOT THEM ###
#################################

# Choose data set you want to work with:
DataSet <- DataSet3_Souvenirs

# Divide traning and test set:
smp_size <- floor(TrainSetSize * length(DataSet))
train_ind <- c(1:smp_size)
train <- DataSet[train_ind]
test <- DataSet[-train_ind]
# Plot data:
plot(train,type = 'l',col='blue',lwd=2,main = '',xlab = 'Time [months]',ylab='',xlim=c(1,length(DataSet)),ylim = c(min(DataSet),max(DataSet)))
lines(c((length(train)+1):(length(DataSet))),test,lwd=2,col='black')
abline(v=length(train),col='grey')
legend('topleft',legend=c('Training Set','Test Set'),col=c('blue','black'),lwd=c(2,2))

##############################
### TIME SERIES ANLYSIS ######
##############################

# Plot ACF and PACF to check stationarity and correlations:
acf(train,main='ACF for Data',length(train)/2)
pacf(train,main='PACF for Data',length(train)/2)

##
# As we can see this data set have a seasonal component every 12 months (for obvious reasons). We can also see an increasing trend and variance in the mean.
# Therefore we will need to work with logarithmic data and we will need to differentiate in order 1 and order 12.  
## 

# Apply transformations if required:
transformdata  <- diff(diff(log(train),12),1)

acf(transformdata,main='ACF for Data',length(train)/2)
pacf(transformdata,main='PACF for Data',length(train)/2)

##
# If we look at the ACF, this looks like more a random walk. We see that there is a significant lag in 1 (q=1) and also we can see that every 12 lags we have a bit of correlation.
# This correlation every 12 lags is not so significat but repeats very frequently, maybe is good to try (Q=1)
# Looking at the PACF, we only see one sifnificant lag (p=1) and no significant lags that repeat on a seasonal basis so (P=0)
# Since we have differentiate in 1 and 12 (d=1 and D=1) giving the seasonal value S=12
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

##
# The residuals dont look so good as previously but that can be because we do not have much training data. If we would have more probably they would look like more "normal"
# It can also be cause the model is overfitted but looking at the qq plot we see that it is not.
# The ACF for the residuals looks very good though. 
##

##############################################
### LETS MAKE PREDICTIONS AND PLOT THEM ######
##############################################

# Predict n.ahead steps:
Predictions <- predict(TS_Model, n.ahead = length(test))

##
# Transfrom this predictions to the exponetial (because we were predicting using the log transform)
##

# Plot predictions:
plot(train,type = 'l',col='blue',lwd=2,main = 'Fill Data',xlab = 'Time',ylab='Data',xlim=c(1,length(DataSet)),ylim = c(0,max(DataSet)))
lines(c((length(train)+1):(length(DataSet))),test,lwd=2,col='gray60')
lines(c((length(train)+1):(length(DataSet))),exp(Predictions$pred),lwd=1,col='red')
lines(c((length(train)+1):(length(DataSet))),exp(Predictions$pred+Predictions$se),lwd=1,lty=2,col='red')
lines(c((length(train)+1):(length(DataSet))),exp(Predictions$pred-Predictions$se),lwd=1,lty=2,col='red')
abline(v=length(train),col='grey')
legend('topleft',legend=c('Past observations','Real Observations','Mean Forecast','95% Conf. Intervals Forecast'),col=c('blue','gray60','red','red'),lwd=c(2,2,1,1),lty=c(1,1,1,2))

##
# These are actually very good predictions. 
##




