### Call for libraries ###
library(tseries)
library(forecast)
### In case it is your first time in R, install them as: ###
#install.packages('tseries')
#install.packages('forecast')


## remember to place this file in the same directory (folder) that the data file are !!!!!!


# Set the directory where you saved the data set
path <- getwd()

# Set fix random generator numbers 
set.seed(0)

##############################
# CHOOSE SIZE OF TRAIN SET ###
##############################

TrainSetSize <- 0.85 # Do not touch this

#####################
### READ DATA SET ###
#####################

DataSet1_Chickenpox   <- na.omit(read.csv(paste0(path,'/monthly-reported-number-of-chick.csv'),sep=';',dec='.')$Monthly.reported.number.of.chickenpox..New.York.city..1931.1972)
DataSet2_Earthquakes  <- na.omit(read.csv(paste0(path,'/number-of-earthquakes-per-year-m.csv'),sep=';',dec='.')$Number.of.earthquakes.per.year.magnitude.7.0.or.greater..1900.1998)
DataSet3_Gifts        <- read.csv(paste0(path,'/sell-souvenirs-USmonthly.csv'),sep=';',dec='.',header = F)$V1

##################################################
##################################################
#### LET US START PREDICTION THE EARTHQUAKES #####
##################################################
##################################################

#################################
### DIVIDE SETS AND PLOT THEM ###
#################################

# Choose data set you want to work with:
DataSet <- DataSet2_Earthquakes

# Divide traning and test set:
smp_size <- floor(TrainSetSize * length(DataSet))
train_ind <- c(1:smp_size)
train <- DataSet[train_ind]
test <- DataSet[-train_ind]
# Plot data:
plot(train,type = 'l',col='red',lwd=2,main = '',xlab = 'Time []',ylab='',xlim=c(1,length(DataSet)),ylim = c(min(DataSet),max(DataSet)))
lines(c((length(train)+1):(length(DataSet))),test,lwd=2,col='black')
abline(v=length(train),col='grey')
legend('topleft',legend=c('Training Set','Test Set'),col=c('red','black'),lwd=c(2,2))


##
# Data seem a bit non stationary since mean does not remain constant for all the quantiles 
##


##############################
### TIME SERIES ANLYSIS ######
##############################

# Plot ACF and PACF to check stationarity and correlations:
acf(train,main='ACF for Data',length(train)/2)
pacf(train,main='PACF for Data',length(train)/2)

##
# The ACF confirms that data are a bit stationary since it takes several lgas for the correlation to decay to zero. Let us differentiate 
##

# Apply transformations if required:
differentiatedata  <- diff(train,1)

acf(differentiatedata,main='ACF for Data',length(train)/2)
pacf(differentiatedata,main='PACF for Data',length(train)/2)

##
# Now the ACF looks more stationary so looking at ACF we see 1 (q=1) significant lag, looking at PACF we see two significant lags (p=2). Since we difrentiate once, d=1.
##

# Create ARIMA order=(p,d,q) or SARIMA order=(p,d,q)x(P,D,Q)S:
p = 2 # AR(p)
d = 1 # differentiate order
q = 1 # MA(q)


TS_Model <- arima(train,order = c(p,d,q))

# Check residuals of the model:
hist(TS_Model$residuals,prob = T,breaks = 20,col='deepskyblue1',main='Histogram residuals')
curve(dnorm(x, mean(TS_Model$residuals), sd(TS_Model$residuals)), add=TRUE, col="red", lwd=2)

qqnorm(TS_Model$residuals,main='Q-Q plot residuals')
qqline(TS_Model$residuals)

plot(c(fitted(TS_Model)),c(TS_Model$residuals),pch=20,col='red',xlab = 'Fitted Values',ylab='Residuals',main='Residual vs Fitted residuals')
abline(h=0)

acf(TS_Model$residuals,length(train)/2,main='ACF for residuals')

##
# Residuals look great and normally distributed. In my humble opinion this model is well fitted. Let us check for the prediction.
##

##############################################
### LETS MAKE PREDICTIONS AND PLOT THEM ######
##############################################

# Predict n.ahead steps:
Predictions <- predict(TS_Model, n.ahead = length(test))
# Plot predictions:
plot(train,type = 'l',col='red',lwd=2,main = 'Fill Data',xlab = 'Time',ylab='Data',xlim=c(1,length(DataSet)),ylim = c(0,max(DataSet)))
lines(c((length(train)+1):(length(DataSet))),test,lwd=2,col='gray60')
lines(c((length(train)+1):(length(DataSet))),Predictions$pred,lwd=2,col='limegreen')
lines(c((length(train)+1):(length(DataSet))),Predictions$pred+Predictions$se,lwd=2,lty=2,col='limegreen')
lines(c((length(train)+1):(length(DataSet))),Predictions$pred-Predictions$se,lwd=2,lty=2,col='limegreen')
abline(v=length(train),col='grey')
legend('topleft',legend=c('Past observations','Real Observations','Mean Forecast','95% Conf. Intervals Forecast'),col=c('red','gray60','limegreen','limegreen'),lwd=c(2,2,2,2),lty=c(1,1,1,2))

##
# Nice predictions, the 95% conf interval cathces the entire test set which means that my scenarios will look awesome (but that will be for the next exercise)
## 

##################################################
##################################################
#### LET US CONTINUE WITH THE SOUVENIRS ##########
##################################################
##################################################

#################################
### DIVIDE SETS AND PLOT THEM ###
#################################

# Choose data set you want to work with:
DataSet <- DataSet3_Gifts

# Divide traning and test set:
smp_size <- floor(TrainSetSize * length(DataSet))
train_ind <- c(1:smp_size)
train <- DataSet[train_ind]
test <- DataSet[-train_ind]
# Plot data:
plot(train,type = 'l',col='blue',lwd=2,main = '',xlab = 'Time []',ylab='',xlim=c(1,length(DataSet)),ylim = c(min(DataSet),max(DataSet)))
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
# Therfore we will need to work with logarithmic data and we will need to differentiate in order 1 and order 12.
##

# Apply transformations if required:
transformdata  <- diff(diff(log(train),12),1)

acf(transformdata,main='ACF for Data',length(train)/2)
pacf(transformdata,main='PACF for Data',length(train)/2)

##
# If we look at the ACF, this looks like more a random walk. We see that thre is a significant lag in 1 (q=1) and also we can see that every 12 lags we have a bit of correlation.
# This correlation every 12 lags is not so significat but repeats very frequently, maybe is good to try (Q=1)
# Looking at the PACF, we only see one sifnificant lag (p=1) and no significant lags that repeat on a seasonal basis so (P=0)
# Since we have differentiate in 1 and 12 (d=1 and D=1) giving the seasonal value S=12
##

# Create ARIMA order=(p,d,q) or SARIMA order=(p,d,q)x(P,D,Q)S:
p = 1# AR(p)
d = 1# differentiate order
q = 1# MA(q)
## Seasonal
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
# The residuals dont look so good as prevously but that can be because we do not have much training data. If we would have more probably they would look like more "normal"
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

##############################################################################################################
##############################################################################################################
#### LET US FINISH WITH THE CHICKENPOX (I have to say that this ones are a bit tricky, so pay attention) #####
##############################################################################################################
##############################################################################################################

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
### TIME SERIES ANLYSIS ######
##############################

# Plot ACF and PACF to check stationarity and correlations:
acf(train,main='ACF for Data',length(train)/2)
pacf(train,main='PACF for Data',length(train)/2)

##
# ACF looks high seasonal, with peaks that increase and decrease very fast, this is a clear seasonality again every 12 months.
# This ups and downs look a high seasonal behaviour in the data 
# We also see in the plot (not the ACF) variability in the peaks, we can remove this peaks by using the log transfrom.
# Variability in the peaks imply that the mean will move also, so we will try to differentiate once apart of the 12th.
## 


plot(log(train),type = 'l',col='darkorange',lwd=2,main = '',xlab = 'Time []',ylab='',xlim=c(1,length(DataSet)),ylim = c(min(log(DataSet)),max(log(DataSet))))
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

##
# The residuals dont look so good as prevously but that can be because we do not have much training data. If we would have more probably they would look like more "normal"
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
plot(train,type = 'l',col='darkorange',lwd=2,main = 'Fill Data',xlab = 'Time',ylab='Data',xlim=c(1,length(DataSet)),ylim = c(0,max(DataSet)))
lines(c((length(train)+1):(length(DataSet))),test,lwd=2,col='gray60')
lines(c((length(train)+1):(length(DataSet))),exp(Predictions$pred),lwd=2,col='darkviolet')
lines(c((length(train)+1):(length(DataSet))),exp(Predictions$pred+Predictions$se),lwd=2,lty=2,col='darkviolet')
lines(c((length(train)+1):(length(DataSet))),exp(Predictions$pred-Predictions$se),lwd=2,lty=2,col='darkviolet')
abline(v=length(train),col='grey')
legend('topleft',legend=c('Past observations','Real Observations','Mean Forecast','95% Conf. Intervals Forecast'),col=c('darkorange','gray60','darkviolet','darkviolet'),lwd=c(2,2,2,2),lty=c(1,1,1,2))

##
# These are actually very good predictions. 
##

