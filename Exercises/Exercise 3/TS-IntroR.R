### Call for libraries ###
library(tseries)
library(forecast)
### In case it is your first time in R, install them as: ###
#install.packages('tseries')
#install.packages('forecast')

# Set the directory where you saved the data set
path <- 'C:\\Users\\~\\TS_DataSet\\'

# Set fix random generator numbers 
set.seed(0)

##############################
# CHOOSE SIZE OF TRAIN SET ###
##############################

TrainSetSize <- 0.85 # Do not touch this

#####################
### READ DATA SET ###
#####################

DataSet1_Chickenpox   <- na.omit(read.csv(paste0(path,'monthly-reported-number-of-chick.csv'),sep=';',dec='.')$Monthly.reported.number.of.chickenpox..New.York.city..1931.1972)
DataSet2_Earthquakes  <- na.omit(read.csv(paste0(path,'number-of-earthquakes-per-year-m.csv'),sep=';',dec='.')$Number.of.earthquakes.per.year.magnitude.7.0.or.greater..1900.1998)
DataSet3_Gifts        <- read.csv(paste0(path,'sell-souvenirs-USmonthly.csv'),sep=';',dec='.',header = F)$V1

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

# Apply transformations if required:
log_transformdata  <- log(train)
sqrt_transformdata <- sqrt(train)
differentiatedata  <- diff(train,1)

# Create ARIMA order=(p,d,q) or SARIMA order=(p,d,q)x(P,D,Q)S:
p = # AR(p)
d = # differentiate order
q = # MA(q)
# Seasonal 
S = # Seasonality  
P = # AR(P) Seasonal
D = # differentiate order Seasonal
Q = # MA(Q) Seasonal
  
TS_Model <- arima(train,order = c(p,d,q))
# If we include seasonality, we use:
TS_Model <- arima(train,order = c(p,d,q), seasonal = list(order = c(P,D,Q), period = S))
# Check residuals of the model:
hist(TS_Model$residuals,prob = T,breaks = 20,col='deepskyblue1',main='Histogram residuals')
curve(dnorm(x, mean(TS_Model$residuals), sd(TS_Model$residuals)), add=TRUE, col="red", lwd=2)

qqnorm(TS_Model$residuals,main='Q-Q plot residuals')
qqline(TS_Model$residuals)

plot(c(fitted(TS_Model)),c(TS_Model$residuals),pch=20,col='red',xlab = 'Fitted Values',ylab='Residuals',main='Residual vs Fitted residuals')
abline(h=0)

acf(TS_Model$residuals,length(DataEst1)/2,main='ACF for residuals')

# Are the residuals OK? Do they look normally distributed? If yes, we move forward. If no, try new transformations or new paramaters

##############################################
### LETS MAKE PREDICTIONS AND PLOT THEM ######
##############################################

# Predict n.ahead steps:
Predictions <- predict(TS_Model, n.ahead = length(test))
# Plot predictions:
plot(train,type = 'l',col='blue',lwd=2,main = 'Fill Data',xlab = 'Time',ylab='Data',xlim=c(1,length(DataSet)),ylim = c(0,max(DataSet)))
lines(c((length(train)+1):(length(DataSet))),test,lwd=2,col='gray60')
lines(c((length(train)+1):(length(DataSet))),Predictions$pred,lwd=1,col='red')
lines(c((length(train)+1):(length(DataSet))),Predictions$pred+Predictions$se,lwd=1,lty=2,col='red')
lines(c((length(train)+1):(length(DataSet))),Predictions$pred-Predictions$se,lwd=1,lty=2,col='red')
abline(v=length(train),col='grey')
legend('topleft',legend=c('Past observations','Real Observations','Mean Forecast','95% Conf. Intervals Forecast'),col=c('blue','gray60','red','red'),lwd=c(2,2,1,1),lty=c(1,1,1,2))

