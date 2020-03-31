# Author:           Jorge Montalvo Arvizu
# Student number:   s192184

#Import packages
using JuMP
using Gurobi
using Printf
using MathOptFormat
using CSV

#Areas
I_names = ["zip2000","zip2800","zip7400","zip8900"]
I = collect(1:4)
#Scenarios
S = collect(1:12)

# Initial price in DKK/m2 in area i, access by p_init[i]
p_init = [42371,32979,15337,14192]

#Budget
B = 25000000

#Forecasted price in DKK/m2 in area i and scenario s
#Reads price data from scenarios.csv file
#Access price by calling p[i,s]
df_p = CSV.read("scenarios.csv", delim=";")
array_p = Array(df_p)
p = zeros(Float32,length(I),length(S))
for i=1:size(array_p,1)
    p[Int(array_p[i,2]),Int(array_p[i,1])]=array_p[i,3]
end

#Probabilities
prob = [0.09 0.13 0.08 0.10 0.08 0.06 0.07 0.10 0.05 0.07 0.12 0.05]

β = 0.2
α = 0.9

#Heat demand forecast per hour and scenario
p_expected = rand(length(I))
for i in I
    p_expected[i] = sum(prob[s]*p[i,s] for s in S)
end

## Expected value model

# Declare Gurobi model
model_EV = Model(with_optimizer(Gurobi.Optimizer))

# Variable definition
@variable(model_EV, x[i in I] >= 0, Int)
@variable(model_EV, y[i in I], Int)

# Objective function
@objective(model_EV, Max, (-sum(p_init[i]*x[i] for i in I) +
    sum(p_expected[i]*y[i] for i in I)))

# Budget balance
@constraint(model_EV, budget_balance, sum(p_init[i]*x[i] for i in I) == B)
# Buy and sell value
@constraint(model_EV, x_y[i in I], y[i] == x[i])

# Optimize and get objective value
optimize!(model_EV)

# Calculate result variables
amount = value.(x).data
investment = transpose(amount)*p_init
future = sum(p_expected[i]*amount[i] for i in I)
gain = future - investment

# Print solution
if termination_status(model_EV) == MOI.OPTIMAL
    @printf "Gain: %.3f\n" gain
    @printf "Objective: %.3f\n" objective_value(model_EV)
   for i in I
       area = I_names[i]
       a = amount[i]
       println("Area $area: $a m²")
   end
else
    error("No solution.")
end


## EV results into stochastic program

# Declare Gurobi model
model_EEV = Model(with_optimizer(Gurobi.Optimizer))

# Variable definition
@variable(model_EEV, x[i in I] >= 0, Int)
@variable(model_EEV, y[i in I], Int)

@objective(model_EEV, Max, -sum(p_init[i]*amount[i] for i in I) +
    sum(prob[s]*p[i,s]*y[i] for i in I for s in S))

# Budget balance
@constraint(model_EEV, budget_balance, sum(p_init[i]*amount[i] for i in I) == B)
# Buy and sell value
@constraint(model_EEV, x_y[i in I], y[i] == amount[i])

# Optimize and get objective value
optimize!(model_EEV)

investment = transpose(amount)*p_init
future = sum(prob[s]*p[i,s]*amount[i] for i in I for s in S)
gain = future - investment
future_s = transpose(amount)*p
gain_s = future_s .- investment

# Print solution
if termination_status(model_EEV) == MOI.OPTIMAL
    @printf "Gain: %.3f\n" gain
    @printf "Objective: %.3f\n" objective_value(model_EEV)
   for i in I
       area = I_names[i]
       a = amount[i]
       println("Area $area: $a m²")
   end
else
    error("No solution.")
end
