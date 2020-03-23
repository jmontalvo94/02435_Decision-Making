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

DataSet2_Earthquakes  <- na.omit(read.csv('number-of-earthquakes-per-year-m.csv',sep=';',dec='.')$Number.of.earthquakes.per.year.magnitude.7.0.or.greater..1900.1998)

#################################
### DIVIDE SETS AND PLOT THEM ###
#################################

# Choose data set you want to work with:
DataSet <- DataSet2_Earthquakes

# Divide training and test set:
smp_size <- floor(TrainSetSize * length(DataSet))
train_ind <- c(1:smp_size)
train <- DataSet[train_ind]
test <- DataSet[-train_ind]
# Plot data:
plot(train,type = 'l',col='red',lwd=2,main = '',xlab = 'Time [years]',ylab='',xlim=c(1,length(DataSet)),ylim = c(min(DataSet),max(DataSet)))
lines(c((length(train)+1):(length(DataSet))),test,lwd=2,col='black')
abline(v=length(train),col='grey')
legend('topleft',legend=c('Training Set','Test Set'),col=c('red','black'),lwd=c(2,2))


##
# Data seem a bit non stationary since the mean does not remain constant for all the quantiles 
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
# Residuals look great and normally distributed. 
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
# Nice predictions, the 95% conf interval contains the entire test set 
## 

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
# Transform the scenarios and plot them
TransformScenarios <- (Scenarios)

plot(train,type = 'l',col='red',lwd=1,main = '',xlab = 'Time [months]',ylab='Number of passengers (thousands)',xlim=c(1,length(DataSet)),ylim = c(min(TransformScenarios),max(TransformScenarios)))
points(train,col='red',pch=20)
for(w in 1:Scen){lines(c((length(train)+1):(length(DataSet))),TransformScenarios[,w],col='grey',lwd=0.5)}
lines(c((length(train)+1):(length(DataSet))),test,lwd=1,col='black')
points(c((length(train)+1):(length(DataSet))),test,pch=20,col='black')
abline(v=length(train),col='grey')
legend('topleft',legend=c('Past observations','Actual Observations','Scenarios'),col=c('red','black','grey'),lwd=c(1,1,1),lty=c(1,1,1))
# Reduce scenarios using Partitions around medoids
Scenarios_pam <- pam(t(TransformScenarios),RedScen)
Scenarios_pam$medoids
plot(train,type = 'l',col='red',lwd=1,main = '',xlab = 'Time [months]',ylab='Number of passengers (thousands)',xlim=c(1,length(DataSet)),ylim = c(min(Scenarios_pam$medoids),max(c(train,Scenarios_pam$medoids))))
points(train,col='red',pch=20)
for(w in 1:RedScen){lines(c((length(train)+1):(length(DataSet))),Scenarios_pam$medoids[w,],col='grey',lwd=0.5)}
lines(c((length(train)+1):(length(DataSet))),test,lwd=1,col='black')
points(c((length(train)+1):(length(DataSet))),test,pch=20,col='black')
abline(v=length(train),col='grey')
legend('topleft',legend=c('Past observations','Actual Observations','Scenarios'),col=c('red','black','grey'),lwd=c(1,1,1),lty=c(1,1,1))
# Probability Distribution for reduced number of scenarios
Probability <- 1/length(1:Scen)
Reduce_prob <- c() 
for (i in 1:RedScen) {
  Reduce_prob[i] <- Probability *length( Scenarios_pam$clustering[ Scenarios_pam$clustering==i])
}
# Store these two values for later use
Earthquake_Scenarios  <- round(t(Scenarios_pam$medoids)*Scen,0)
Probability_Scenarios <- Reduce_prob

Earthquake_CSV <- Earthquake_Scenarios
colnames(Earthquake_CSV) <- c(',s1',paste0('s',2:RedScen))
rownames(Earthquake_CSV) <- paste0('t',1:length(test))

Probability_CSV <- matrix(Probability_Scenarios,RedScen,1)
rownames(Probability_CSV) <- paste0('s',1:RedScen)

write.table(Earthquake_CSV,file =  'Scenarios-Earthquakes.csv', sep=",",  dec=".",row.names=TRUE,col.names=TRUE,quote=FALSE)
write.table(Probability_CSV,file =  'Probability-Earthquakes.csv', sep=",",  dec=".",row.names=TRUE,col.names=FALSE,quote=FALSE)


