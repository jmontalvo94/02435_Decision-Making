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

## Two-stage stochastic model with CVaR

# Declare Gurobi model
model_investment = Model(with_optimizer(Gurobi.Optimizer))

# Variable definition
@variable(model_investment, x[i in I] >= 0, Int)
@variable(model_investment, y[i in I], Int)
@variable(model_investment, η)
@variable(model_investment, δ[s in S] >= 0)

@objective(model_investment, Max, (1-β)*(-sum(p_init[i]*x[i] for i in I) +
    sum(prob[s]*p[i,s]*y[i] for i in I for s in S)) +
    β*(η - (1/(1-α))*sum(prob[s]*δ[s] for s in S)))

# Budget balance
@constraint(model_investment, budget_balance, sum(p_init[i]*x[i] for i in I) == B)
# Buy and sell value
@constraint(model_investment, x_y[i in I], y[i] == x[i])
# CVaR
@constraint(model_investment, cvar[s in S], η - (-sum(p_init[i]*x[i] for i in I) +
    sum(p[i,s]*y[i] for i in I)) <= δ[s])

# Optimize and get objective value
optimize!(model_investment)

# Calculate result variables
amount = value.(x).data
investment = transpose(amount)*p_init
future = sum(prob[s]*p[i,s]*amount[i] for i in I for s in S)
gain = future - investment
cvar = value.(η) - (1/(1-α))*(prob*(value.(δ).data))[1]
future_s = transpose(amount)*p
gain_s = future_s .- investment

# Print solution
if termination_status(model_investment) == MOI.OPTIMAL
    @printf "Gain: %.3f\n" gain
    @printf "CVaR: %.3f\n" cvar
    @printf "Objective: %.3f\n" objective_value(model_investment)
   for i in I
       area = I_names[i]
       a= amount[i]
       println("Area $area: $a m²")
   end
else
    error("No solution.")
end
