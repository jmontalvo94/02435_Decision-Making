
library(tseries)
library(forecast)
set.seed(0)
path <- 'C:\\Users\\igbl\\Desktop\\LinearTS\\DataSet\\Exercise\\'

##############################
# CHOOSE SIZE OF TRAIN SET ###
##############################

TrainSetSize <- 0.85 

DataSet1_GNPpercapita <- na.omit(read.csv(paste0(path,'annual-real-per-capita-gnp-us-19.csv'),sep=';',dec='.')$Annual.real.per.capita.GNP..U.S...1909.to.1970)
DataSet2_Lakelevels   <- na.omit(read.csv(paste0(path,'monthly-lake-erie-levels-1921-19.csv'),sep=';',dec='.')$Monthly.Lake.Erie.Levels.1921...1970.)
DataSet3_murdersNY    <- na.omit(read.csv(paste0(path,'monthly-reported-number-of-cases.csv'),sep=';',dec='.')$Monthly.reported.number.of.cases.of.mumps..New.York.city..1928.1972)
DataSet4_Chickenpots  <- na.omit(read.csv(paste0(path,'monthly-reported-number-of-chick.csv'),sep=';',dec='.')$Monthly.reported.number.of.chickenpox..New.York.city..1931.1972)
DataSet5_Earthquakes  <- na.omit(read.csv(paste0(path,'number-of-earthquakes-per-year-m.csv'),sep=';',dec='.')$Number.of.earthquakes.per.year.magnitude.7.0.or.greater..1900.1998)
DataSet6_Gifts        <- read.csv(paste0(path,'Gifts.csv'),sep=';',dec='.',header = F)$V1
DataSet7_ManOlimpics  <- na.omit(read.csv(paste0(path,'winning-times-for-the-mens-400-m.csv'),sep=';',dec='.')$Winning.times.for.the.men.s.400.m.final.in.each.Olympic.Games.from.1896.to.1996)
DataSet8_PowerDemand  <- read.csv(paste0(path,'EDemandDK2_1_20_Nov.csv'),sep=';',dec=',',header = F)$V1 
DataSet9_PopulationAustralia  <- na.omit(read.csv(paste0(path,'estimated-quarterly-resident-pop.csv'),sep=';',dec='.')$Estimated.quarterly.resident.population.of.Australia..thousand.persons) 
DataSet10_VEks                <- read.csv(paste0(path,'veks.csv'),sep=',',dec='.')$HC.f[2500:5500]
DataSet11_NOx                 <- read.csv(paste0(path,'NOx_Data.csv'),sep=';',dec=',',header=F)$V1

##############################
### TIME SERIES ANLYSIS ######
##############################

## EARTHQUAKES ARIMA(2,1,1)
## SOUVENIRS   SARIMA(1,0,2)x(1,1,0)_12
## CHICKENPOX  SARIMA(1,0,1)x(0,1,1)_12 After sqrt transform of the data

### EARTHQUAKES ###

DataSet <- DataSet5_Earthquakes

smp_size <- floor(TrainSetSize * length(DataSet))
train_ind <- c(1:smp_size)
train <- DataSet[train_ind]
test <- DataSet[-train_ind]

plot(train,type = 'l',col='red',lwd=2,main = 'Earthquakes grater than magnitude 7.0 registered from 1900 to 1998',xlab = 'Time [years]',ylab='# Earthquackes',xlim=c(1,length(DataSet)),ylim = c(min(DataSet),max(DataSet)))
lines(c((length(train)+1):(length(DataSet))),test,lwd=2,col='black')
abline(v=length(train),col='grey')
legend('topleft',legend=c('Training Set','Test Set'),col=c('red','black'),lwd=c(2,2))


plot(diff(train),type = 'l',col='red',lwd=2,main = 'diff1(Fill Data)',xlab = 'Time',ylab='Data')

acf(diff(train),main='ACF for Data',length(train)/2)

pacf(diff(train),main='PACF for Data',length(train)/2)

TS_Model <- arima(train,order = c(2,1,1))

hist(TS_Model$residuals,prob = T,breaks = 20,col='deepskyblue1',main='Histogram residuals')
curve(dnorm(x, mean(TS_Model$residuals), sd(TS_Model$residuals)), add=TRUE, col="red", lwd=2)

qqnorm(TS_Model$residuals,main='Q-Q plot residuals ARIMA(1,0,5)')
qqline(TS_Model$residuals)

plot(c(fitted(TS_Model)),c(TS_Model$residuals),pch=20,col='red',xlab = 'Fitted Values',ylab='Residuals',main='Residual vs Fitted residuals ARIMA(1,0,5)')
abline(h=0)

acf(TS_Model$residuals,length(DataEst1)/2,main='ACF for residuals')
pacf(TS_Model$residuals,length(DataEst1)/2,main='PACF for residuals')

Predictions <- predict(TS_Model, n.ahead = length(test))

plot(train,type = 'l',col='red',lwd=2,main = 'Fill Data',xlab = 'Time',ylab='Data',xlim=c(1,length(DataSet)),ylim = c(0,max(DataSet)))
lines(c((length(train)+1):(length(DataSet))),test,lwd=2,col='black')
lines(c((length(train)+1):(length(DataSet))),Predictions$pred,lwd=2,col='forestgreen')
lines(c((length(train)+1):(length(DataSet))),Predictions$pred+Predictions$se,lwd=2,lty=2,col='forestgreen')
lines(c((length(train)+1):(length(DataSet))),Predictions$pred-Predictions$se,lwd=2,lty=2,col='forestgreen')
abline(v=length(train),col='grey')
legend('topleft',legend=c('Past observations','Observations','Forecast'),col=c('red','black','forestgreen'),lwd=c(2,2,2),lty=c(1,1,1))


##### GIFTS #####

DataSet <- DataSet6_Gifts

smp_size <- floor(TrainSetSize * length(DataSet))
train_ind <- c(1:smp_size)
train <- DataSet[train_ind]
test <- DataSet[-train_ind]

plot(train,type = 'l',col='royalblue3',lwd=2,main = 'Souvenir sales is from January 1987 to December 1993 in US',xlab = 'Time [months]',ylab='USM$',xlim=c(1,length(DataSet)),ylim = c(min(DataSet),max(DataSet)))
lines(c((length(train)+1):(length(DataSet))),test,lwd=2,col='black')
abline(v=length(train),col='grey')
legend('topleft',legend=c('Training Set','Test Set'),col=c('royalblue3','black'),lwd=c(2,2))



acf(train,main='ACF for Data',length(train)/2)

## Data is non stationary, we need to diferenciate ##

plot(diff(log(train),12),type = 'l',col='red',lwd=2,main = 'diff1(Fill Data)',xlab = 'Time',ylab='Data')

## Let us look at the ACF 

acf(diff(log(train),12),main='ACF for Data',length(train)/4)

## Seems good, let us check the PACF 

pacf(diff(log(train),12),main='ACF for Data',length(train)/4)

## Also fine! Let us try to fit an ARIMA(1,1,1)

TS_Model <- arima(log(train),order = c(1,0,2),seasonal = list(order = c(1,1,0), period = 12))

## Let us check if the residuals follow a normal distribution

hist(TS_Model$residuals,prob = T,breaks = 20,col='deepskyblue1',main='Histogram residuals')
curve(dnorm(x, mean(TS_Model$residuals), sd(TS_Model$residuals)), add=TRUE, col="red", lwd=2)

qqnorm(TS_Model$residuals,main='Q-Q plot residuals ARIMA(1,0,5)')
qqline(TS_Model$residuals)

plot(c(fitted(TS_Model)),c(TS_Model$residuals),pch=20,col='red',xlab = 'Fitted Values',ylab='Residuals',main='Residual vs Fitted residuals ARIMA(1,0,5)')
abline(h=0)

acf(TS_Model$residuals,length(DataEst1)/2,main='ACF for residuals')
pacf(TS_Model$residuals,length(DataEst1)/2,main='PACF for residuals')

# Let us predict 

Predictions <- predict(TS_Model, n.ahead = length(test))

plot(train,type = 'l',col='red',lwd=2,main = 'Fill Data',xlab = 'Time',ylab='Data',xlim=c(1,length(DataSet)),ylim = c(min(DataSet),max(DataSet)))
lines(c((length(train)+1):(length(DataSet))),test,lwd=2,col='black')
lines(c((length(train)+1):(length(DataSet))),exp(Predictions$pred),lwd=2,col='forestgreen')
lines(c((length(train)+1):(length(DataSet))),exp(Predictions$pred+Predictions$se),lwd=2,lty=2,col='forestgreen')
lines(c((length(train)+1):(length(DataSet))),exp(Predictions$pred-Predictions$se),lwd=2,lty=2,col='forestgreen')
abline(v=length(train),col='grey')
legend('topleft',legend=c('Past observations','Observations','Forecast'),col=c('red','black','forestgreen'),lwd=c(2,2,2),lty=c(1,1,2))


### CHickenpox Case in NY ###

DataSet <- DataSet4_Chickenpots
smp_size <- floor(TrainSetSize * length(DataSet))
train_ind <- c(1:smp_size)
train <- DataSet[train_ind]
test <- DataSet[-train_ind]

plot(train,type = 'l',col='darkorange2',lwd=2,main = 'Monthly reported cases of Chickenpox in NY City from 1931 to 1972',xlab = 'Time [months]',ylab='# Cases',xlim=c(1,length(DataSet)),ylim = c(min(DataSet),max(DataSet)))
lines(c((length(train)+1):(length(DataSet))),test,lwd=2,col='black')
abline(v=length(train),col='grey')
legend('topleft',legend=c('Training Set','Test Set'),col=c('darkorange2','black'),lwd=c(2,2))

acf(train,type="correlation",main='Auto-correlation')
pacf(train ,main='Partial ACF')

acf(diff(train,12),type="correlation",main='Auto-correlation')
pacf(diff(train,12) ,main='Partial ACF')

TS_Model <- arima(train,order = c(1,0,0),seasonal = list(order = c(0,1,1), period = 12))

hist(TS_Model$residuals,prob = T,breaks = 20,col='deepskyblue1',main='Histogram residuals')
curve(dnorm(x, mean(TS_Model$residuals), sd(TS_Model$residuals)), add=TRUE, col="red", lwd=2)

qqnorm(TS_Model$residuals,main='Q-Q plot residuals ARIMA(1,0,5)')
qqline(TS_Model$residuals)

plot(c(fitted(TS_Model)),c(TS_Model$residuals),pch=20,col='red',xlab = 'Fitted Values',ylab='Residuals',main='Residual vs Fitted residuals ARIMA(1,0,5)')
abline(h=0)

acf(TS_Model$residuals,length(DataEst1)/2,main='ACF for residuals')
pacf(TS_Model$residuals,length(DataEst1)/2,main='PACF for residuals')

TS_Model <- arima(sqrt(train),order = c(1,0,1),seasonal = list(order = c(0,1,1), period = 12))

hist(TS_Model$residuals,prob = T,breaks = 20,col='deepskyblue1',main='Histogram residuals')
curve(dnorm(x, mean(TS_Model$residuals), sd(TS_Model$residuals)), add=TRUE, col="red", lwd=2)

qqnorm(TS_Model$residuals,main='Q-Q plot residuals ARIMA(1,0,5)')
qqline(TS_Model$residuals)

plot(c(fitted(TS_Model)),c(TS_Model$residuals),pch=20,col='darkorange2',xlab = 'Fitted Values',ylab='Residuals',main='Residual vs Fitted residuals ARIMA(1,0,5)')
abline(h=0)

acf(TS_Model$residuals,length(DataEst1)/2,main='ACF for residuals')

Predictions <- predict(TS_Model, n.ahead = length(test))


plot(train,type = 'l',col='darkorange2',lwd=2,main = 'Fill Data',xlab = 'Time',ylab='Data',xlim=c(1,length(DataSet)),ylim = c(min(DataSet),max(DataSet)))
lines(c((length(train)+1):(length(DataSet))),test,lwd=2,col='black')
lines(c((length(train)+1):(length(DataSet))),(Predictions$pred)^2,lwd=2,col='forestgreen')
lines(c((length(train)+1):(length(DataSet))),(Predictions$pred+Predictions$se)^2,lwd=2,lty=2,col='forestgreen')
lines(c((length(train)+1):(length(DataSet))),(Predictions$pred-Predictions$se)^2,lwd=2,lty=2,col='forestgreen')
abline(v=length(train),col='grey')
legend('topleft',legend=c('Past observations','Observations','Forecast'),col=c('darkorange2','black','forestgreen'),lwd=c(2,2,2),lty=c(1,1,2))

