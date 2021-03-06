#########################################################################
## Task 1 and 2:                                                       ##
## Linear Time Series Analysis and Scenario generation                 ##
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

plot_series <- function(series,yl='Price [DKK/m2]'){
  plot(series, type='l', col='firebrick1', lwd=2, main='', xlab='Time Period', ylab=yl)
}

plot_acf <- function(series, name='Data'){
  acf(series, main=paste('ACF for',name), length(series)/2)
}

plot_pacf <- function(series, name='Data'){
  pacf(series, main=paste('PACF for',name), length(series)/2)
}

plot_hist_norm <- function(model, name='Data'){
  hist(model$residuals, prob=T, breaks=20, col='dodgerblue4', main=paste('Residuals for',name), xlab='Residuals')
  curve(dnorm(x, mean(model$residuals), sd(model$residuals)), add=TRUE, col="cornflowerblue", lwd=2)
}

plot_qq <- function(model, name='Data'){
  qqnorm(model$residuals,main=paste('Q-Q plot for', name), pch=19, col='darkblue')
  qqline(model$residuals)
}

plot_residuals <- function(model, name='Data'){
  plot(c(fitted(model)),c(model$residuals),pch=19,col='darkblue',xlab = 'Fitted Values',ylab='Residuals',main=paste('Residual vs Fitted residuals for',name))
  abline(h=0)
}

plot_residuals <- function(model, name='Data'){
  plot(c(fitted(model)),c(model$residuals),pch=19,col='darkblue',xlab = 'Fitted Values',ylab='Residuals',main=paste('Residual vs Fitted residuals for',name))
  abline(h=0)
}

plot_predictions <- function(model=given_model, main_add='', from_x=1, from_y=0, scenarios_data, scenarios_add=FALSE, color, num_scenarios, reduced=FALSE){
  plot(train, type='l', col='darkblue', lwd=2, main=paste('Price forecast',main_add), xlab='Time Period', ylab='Price [DKK/m2]', xlim=c(from_x,nrow(df)), ylim = c(from_y,max(exp(predictions$pred+predictions$se))))
  if (scenarios_add) {
    for(w in 1:num_scenarios){
      lines(c(tail(samples,1),tail(samples,1)+1), y=c(tail(train,1),scenarios_data[,w]), col=color[w], type="l", lty=1, lwd=2)
      if (reduced){
        legend('topleft',legend=c('Past observations',paste0(rep('Scenario ',10),seq(1:10))), col=c('darkblue',color), lwd=c(2,rep(2,10)),lty=c(1,rep(1,10)), y.intersp=0.8)
      }
    }
  } else {
    lines(c(tail(samples,1),tail(samples,1)+1), y=c(tail(train,1),exp(predictions$pred[1])), lwd=2, col='red')
    lines(c(tail(samples,1),tail(samples,1)+1), y=c(tail(train,1),exp(predictions$pred[1]+predictions$se[1])), lwd=2, lty='dotted', col='salmon')
    lines(c(tail(samples,1),tail(samples,1)+1), y=c(tail(train,1),exp(predictions$pred[1]-predictions$se[1])), lwd=2, lty='dotted', col='salmon')
    legend('topleft',legend=c('Past observations','Forecast','95% Conf. Intervals Forecast'),col=c('darkblue','red','salmon'), lwd=c(2,2,2),lty=c(1,1,3))
  }
  abline(v=length(train), col=alpha('grey',0.8), lty=2)
}

# Load data ---------------------------------------------------------------

# Set path
path <- getwd()

# Set fix random generator numbers
set.seed(0)

# Set train/test split to 1 (all data used to get the model)
train_test_split <- 1

# Read data
df <- read.csv(paste0(path,'prices.csv'), sep=';')


# Exploratory Analysis --------------------------------------------------------------

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

# Split train set into four splits to see mean and variance
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

# Plot series with and without split check
plot_series(train)
plot_series(train)
for (i in 1:4) {
  mtext(paste('Split ',i), side=3, line=1, at=mean(indexes[[i]]))
  abline(v=max(indexes[[i]]), col='gray', lty=5)
  segments(min(indexes[[i]]), mean_vector[i], x1=max(indexes[[i]]), y1=mean_vector[i], col=alpha('darkblue', 0.4), lwd=2, lty=1)
  segments(min(indexes[[i]]), mean_vector[i]+stdev_vector[i], x1=max(indexes[[i]]), y1=mean_vector[i]+stdev_vector[i], col=alpha('cornflowerblue', 0.2), lwd=2)
  segments(min(indexes[[i]]), mean_vector[i]-stdev_vector[i], x1=max(indexes[[i]]), y1=mean_vector[i]-stdev_vector[i], col=alpha('cornflowerblue', 0.2), lwd=2)
  abline(lm(zip2000 ~ Period, data=df), col=alpha('gray',0.5), lwd=2, lty=2)
}


# Fitting the model ----------------------------------------------------

# ACF and PACF on clean data
par(mfrow=c(1,2))
plot_acf(train,'prices')
plot_pacf(train,'prices')

# ACF and PACF on differentiated data
diff_price <- diff(train, 1)
plot_acf(diff_price,'diff(prices)')
plot_pacf(diff_price,'diff(prices)')
par(mfrow=c(1,1))
plot_series(diff_price,'diff(prices)')

# ACF and PACF on log of data
log_train <- log(train)
par(mfrow=c(1,2))
plot_acf(log_train,'log(prices)')
plot_pacf(log_train,'log(prices)')
par(mfrow=c(1,1))
plot_series(log_train,'log(prices)')

# ACF and PACF on transformed and differentiated data
diff_logprice <- diff(log_train, 1)
par(mfrow=c(1,2))
plot_acf(diff_logprice,'diff(log(prices))')
plot_pacf(diff_logprice,'diff(log(prices))')
par(mfrow=c(1,1))
plot_series(diff_logprice,'diff(log(prices))')

# Create ARIMA order=(p,d,q)
p = 1 # AR(p)
d = 1 # Differentiate order
q = 4 # MA(q)

# Create time series models
TS_Model1 <- arima(log_train, order = c(p,d,q))
TS_Model2 <- arima(log_train, order = c(p,d,q+1))
TS_Model_auto <- auto.arima(log_train)


# Diagnostics ------------------------------------------------------

# Plot histogram with normal distribution
par(mfrow=c(1,3))
plot_hist_norm(TS_Model1, 'TS_Model1')
plot_hist_norm(TS_Model2, 'TS_Model2')
plot_hist_norm(TS_Model_auto,'TS_Model_auto')

# Plot qq-plot
plot_qq(TS_Model1, 'TS_Model1')
plot_qq(TS_Model2, 'TS_Model2')
plot_qq(TS_Model_auto,'TS_Model_auto')

# Plot residuals
plot_residuals(TS_Model1, 'TS_Model1')
plot_residuals(TS_Model2, 'TS_Model2')
plot_residuals(TS_Model_auto,'TS_Model_auto')

# Plot ACF of residuals
plot_acf(TS_Model1$residuals, 'TS_Model1 residuals')
plot_acf(TS_Model2$residuals, 'TS_Model2 residuals')
plot_acf(TS_Model_auto$residuals, 'TS_Model_auto residuals')

# Get AIC from each model
TS_Model1$aic
TS_Model2$aic
TS_Model_auto$aic

# Read summaries
summary(TS_Model1)
summary(TS_Model2)
summary(TS_Model_auto)

model <- TS_Model1

# Predictions --------------------------------------------------------------

# Predict n.ahead steps (1)
n <- 1
predictions <- predict(model, n.ahead=length(test)+n)

# Plot predictions with confidence intervals
par(mfrow=c(1,1))
plot_predictions(model)
plot_predictions(model, main_add = 'zoom', from_x=90, from_y = 30000)

# Print prediction and confidence intervals
exp(predictions$pred[1])
exp(predictions$pred[1]+predictions$se[1])
exp(predictions$pred[1]-predictions$se[1])


# Scenarios generation ----------------------------------------------------

# Define number of total scenarios
omega <- 100

# Allocate memory to scenarios matrix
scenarios <- matrix(0, nrow=n, ncol=omega)

# Predict 100 scenarios with selected model
for(w in 1:omega){
  scenarios[n,w]  <- simulate(TS_Model1, nsim=n, future=TRUE, seed=w)
}

# Plot the scenarios
colors <- rainbow(omega)
plot_predictions(model, main_add='scenarios', scenarios_data=exp(scenarios), scenarios_add=TRUE, color=colors, num_scenarios=omega)
plot_predictions(model, main_add='scenarios (zoom)', from_x=90, from_y=30000, scenarios_data=exp(scenarios), scenarios_add=TRUE, color=colors, num_scenarios=omega)


# Scenarios reduction -----------------------------------------------------

# Define reduced scenarios
reduced_omega <- 10

# Create clustering with PAM method
clustering <- pam(t(scenarios),reduced_omega)
reduced_scenarios <- t(clustering$medoids) 

# Plot reduced set of scenarios
colors <- rainbow(reduced_omega)
plot_predictions(model, main_add='- Reduced scenarios', scenarios_data=exp(reduced_scenarios), scenarios_add=TRUE, color=colors, num_scenarios=reduced_omega, reduced=TRUE)
plot_predictions(model, main_add='- Reduced scenarios (zoom)', from_x=90, from_y=30000, scenarios_data=exp(reduced_scenarios), scenarios_add=TRUE, color=colors, num_scenarios=reduced_omega, reduced=TRUE)

# Probability Distribution for reduced number of scenarios
probability <- 1/length(1:omega)
reduced_probability <- 0
for (i in 1:reduced_omega) {
  reduced_probability[i] <- probability*length(clustering$clustering[clustering$clustering==i])
}