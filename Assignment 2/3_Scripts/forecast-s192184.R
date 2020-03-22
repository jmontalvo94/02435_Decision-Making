#########################################################################
## Task 1:                                                             ##
## Linear Time Series Analysis                                         ##
##                                                                     ##
## Author:          Jorge Montalvo Arvizu                              ##
## Student Number:  s192184                                            ##
#########################################################################

# Load libraries
library(tseries)
library(forecast)
library(cluster)
library(scales)


# Create functions --------------------------------------------------------

plot_series <- function(series){
  plot(series, type='l', col='firebrick1', lwd=2, main='', xlab='Time Period', ylab='Price [DKK/m2]')
}

plot_acf <- function(series){
  acf(series, main='ACF for Data', length(series)/2)
}

plot_pacf <- function(series){
  pacf(series, main='PACF for Data', length(series)/2)
}

plot_hist_norm <- function(model){
  hist(model$residuals, prob=T, breaks=20, col='deepskyblue1', main='Histogram Residuals', xlab='Residuals')
  curve(dnorm(x, mean(model$residuals), sd(model$residuals)), add=TRUE, col="red", lwd=2)
}

plot_qq <- function(model){
  qqnorm(model$residuals,main='Q-Q plot residuals')
  qqline(model$residuals)
}

plot_residuals <- function(model){
  plot(c(fitted(model)),c(model$residuals),pch=20,col='red',xlab = 'Fitted Values',ylab='Residuals',main='Residual vs Fitted residuals')
  abline(h=0)
}


# Load data ---------------------------------------------------------------

# Set path
path <- getwd()

# Set fix random generator numbers
set.seed(0)

# Set train/test split
train_test_split <- 1

# Read data
df <- read.csv(paste(path,'prices.csv'), sep=';')


# Stationary --------------------------------------------------------------

# Split data into train/test sets
sample_size <- floor(train_test_split * nrow(df))
samples <- seq(1,sample_size,1)
train_index <- c(1:sample_size)
train <- df$zip2000[train_index]
test <- df$zip2000[-train_index]

# Preallocate vectors to memory
mean_vector <- vector(length=4)
variance_vector <- vector(length=4)
stdev_vector <- vector(length=4)
indexes <- vector(mode="list", length=4)
last <- 0

# Split train set into four periods
splitted_train <- split(train, rep(1:4, length.out=length(train), each=ceiling(length(train)/4)))
for (i in 1:4) {
  indexes[[i]] <- seq(from=last+1, length.out=length(splitted_train[[i]]))
  last <- last+length(splitted_train[[i]])
}

# Obtain mean and variance for each split
for (i in 1:4) {
  mean_vector[i] <- mean(splitted_train[[i]])
  variance_vector[i] <- var(splitted_train[[i]])
  stdev_vector[i] <- sqrt(variance_vector[i])
}

# Plot series
plot(train, type='l', col='firebrick1', lwd=2, main='', xlab='Time Period', ylab='Price [DKK/m2]')
for (i in 1:4) {
  mtext(paste('Split ',i), side=3, line=1, at=mean(indexes[[i]]))
  abline(v=max(indexes[[i]]), col='gray', lty=5)
  segments(min(indexes[[i]]), mean_vector[i], x1=max(indexes[[i]]), y1=mean_vector[i], col=alpha('darkblue', 0.4), lwd=2, lty=1)
  segments(min(indexes[[i]]), mean_vector[i]+stdev_vector[i], x1=max(indexes[[i]]), y1=mean_vector[i]+stdev_vector[i], col=alpha('cornflowerblue', 0.2), lwd=2)
  segments(min(indexes[[i]]), mean_vector[i]-stdev_vector[i], x1=max(indexes[[i]]), y1=mean_vector[i]-stdev_vector[i], col=alpha('cornflowerblue', 0.2), lwd=2)
  abline(lm(zip2000 ~ Period, data=df), col=alpha('gray',0.5), lwd=2, lty=2)
}

# Time Series Analysis ----------------------------------------------------

# ACF and PACF on clean data
plot_acf(train)
plot_pacf(train)

# ACF and PACF on log of data
log_train <- log(train)
plot_acf(log_train)
plot_pacf(log_train)
plot_series(log_train)

# ACF and PACF on transformed and differentiated data
diff_price <- diff(log_train, 1)
plot_acf(diff_price)
plot_pacf(diff_price)
plot_series(diff_price)

# Create ARIMA order=(p,d,q)
p = 1 # AR(p)
d = 1 # Differentiate order
q = 4 # MA(q)

# Create time series models
TS_Model <- arima(log_train, order = c(p,d,q))
TS_Model_auto <- auto.arima(log_train)


# Checking residuals ------------------------------------------------------

# Plot histogram with normal distribution
plot_hist_norm(TS_Model)
plot_hist_norm(TS_Model_auto)

plot_qq(TS_Model)
plot_qq(TS_Model_auto)

plot_residuals(TS_Model)
plot_residuals(TS_Model_auto)

plot_acf(TS_Model$residuals)
plot_acf(TS_Model_auto$residuals)

TS_Model$aic
TS_Model_auto$aic

# Prediction --------------------------------------------------------------

# Predict n.ahead steps:
predictions <- predict(TS_Model, n.ahead=length(test)+1)

# Plot predictions:
plot(train, type='l', col='red', lwd=2, main='Prediction', xlab='Time Period', ylab='Price [DKK/m2]', xlim=c(1,nrow(df)), ylim = c(0,max(exp(predictions$pred+predictions$se))))
#lines(c((length(train)+1):(length(df$zip2000))), test, lwd=2, col='gray60')
lines(c((length(train)+1):(length(train)+1)), exp(predictions$pred), lwd=2, col='limegreen')
lines(c((length(train)+1):(length(train)+1)), exp(predictions$pred+predictions$se), lwd=2, lty=2, col='limegreen')
lines(c((length(train)+1):(length(train)+1)), exp(predictions$pred-predictions$se), lwd=2, lty=2, col='limegreen')
abline(v=length(train), col='grey')
legend('topleft',legend=c('Past observations','Real Observations','Mean Forecast','95% Conf. Intervals Forecast'),col=c('red','gray60','limegreen','limegreen'),lwd=c(2,2,2,2),lty=c(1,1,1,2))
