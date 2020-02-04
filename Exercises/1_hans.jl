#Import packages
using JuMP
using Gurobi
using Printf

#Declare model with Gurobi solver
model_hans = Model(with_optimizer(Gurobi.Optimizer))

#Declare variables with lower bound 0
@variable(model_hans, 0<=x1)
@variable(model_hans, 0<=x2)
@variable(model_hans, 0<=x3)

#Declare minimization of costs objective function
@objective(model_hans, Min, 70x1 + 35x2 + 84x3)

#Declare constraint for minimum of lubricant 1
@constraint(model_hans, Lubricant1, 2x1 + x2 + 5x3 >= 30)
#Declare constraint for minimum of lubricant 2
@constraint(model_hans, Lubricant2, x1 + 3x2 + x3 >= 18)

#Optimize model
optimize!(model_hans)

#Check if optimal solution was found
if termination_status(model_hans) == MOI.OPTIMAL
    println("Optimal solution found")

    #Print out variable values and objective value
    println("Variable values:")
    @printf "x1: %0.3f\n" value.(x1)
    @printf "x2: %0.3f\n" value.(x2)
    @printf "x3: %0.3f\n" value.(x3)
    @printf "\nObjective value: %0.3f\n" objective_value(model_hans)

    #Print out dual variable values
    println("Dual values:")
    @printf "Lubricant 1: %0.3f\n" dual.(Lubricant1)
    @printf "Lubricant 2: %0.3f\n" dual.(Lubricant2)




else
    error("No solution.")
end
