#Import packages
using JuMP
using Gurobi
using Printf

#Declare model with Gurobi solver
model_carl = Model(with_optimizer(Gurobi.Optimizer))

#Declare INTEGER variables with lower bound 0 and upper bound
@variable(model_carl, 0<=xC<=50, Int)
@variable(model_carl, 0<=xS<=200, Int)
#Declare BINARY variables with lower bound 0
@variable(model_carl, 0<=yS, Bin)
@variable(model_carl, 0<=yC, Bin)

#Declare maximization of profits objective function
@objective(model_carl, Max, 250xC + 45xS - 1000yC)
#Constraint on available acres
@constraint(model_carl, Acres, xC + 0.2xS <= 72)
#Constraint on maximum working hours
@constraint(model_carl, WorkingHours, 150xC + 25xS <= 10000)
#Minimum of 100 sheep constraint
@constraint(model_carl, AtLeast100Sheep1, xS - 100yS >= 0)
@constraint(model_carl, AtLeast100Sheep2, xS - 200yS <= 0)
#Maximum of 10 cows without milk machine
@constraint(model_carl, MilkMachine1, xC - 10-40yC<= 0)
@constraint(model_carl, MilkMachine2, xC - 11yC >= 0)

#Optimize model
optimize!(model_carl)

#Check if optimal solution was found
if termination_status(model_carl) == MOI.OPTIMAL
    println("Optimal solution found")

    #Print out variable values and objective value
    println("Variable values:")
    @printf "xC: %0.3f\n" value.(xC)
    @printf "xS: %0.3f\n" value.(xS)
    @printf "yS: %0.3f\n" value.(yS)
    @printf "yC: %0.3f\n" value.(yC)
    @printf "\nObjective value: %0.3f\n\n" objective_value(model_carl)

else
    error("No solution.")
end
