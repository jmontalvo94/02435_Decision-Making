#Import packages
using JuMP
using Gurobi
using Printf

#Declare model with Gurobi solver
model_pepita = Model(with_optimizer(Gurobi.Optimizer))

#Declare variables with lower bound 0
@variable(model_pepita, 0<=y1)
@variable(model_pepita, 0<=y2)

#Declare maximization of profits objective function
@objective(model_pepita, Max, 30y1 + 18y2)

#Declare constraint maximum price on lubricant combination based on natural oil 1
@constraint(model_pepita, NaturalOil1, 2y1 + y2 <= 70)
#Declare constraint maximum price on lubricant combination based on natural oil 2
@constraint(model_pepita, NaturalOil2, y1 + 3y2 <= 35)
#Declare constraint maximum price on lubricant combination based on natural oil 3
@constraint(model_pepita, NaturalOil3, 5y1 + y2 <= 84)

#Optimize model
optimize!(model_pepita)

#Check if optimal solution was found
if termination_status(model_pepita) == MOI.OPTIMAL
    println("Optimal solution found")
    #Print out variable values and objective value
    println("Variable values:")
    @printf "y1: %0.3f\n" value.(y1)
    @printf "y2: %0.3f\n" value.(y2)
    @printf "\nObjective value: %0.3f\n" objective_value(model_pepita)

    #Print out dual variable values
    println("Dual values:")
    @printf "Natural Oil 1: %0.3f\n" dual.(NaturalOil1)
    @printf "Natural Oil 2: %0.3f\n" dual.(NaturalOil2)
    @printf "Natural Oil 3: %0.3f\n" dual.(NaturalOil3)


else
    error("No solution.")
end
