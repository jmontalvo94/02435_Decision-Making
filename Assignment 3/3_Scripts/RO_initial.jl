using JuMP, Gurobi, Printf

clearconsole()

initial = Model(with_optimizer(Gurobi.Optimizer))

# Definition of variables with lower bound 0
@variable(initial, -2<=x1<=10)
@variable(initial, 0<=x2<=15)
@variable(initial, -10<=x3<=10)

@objective(initial, Max, 10x1+20x2+15x3)

@constraint(initial, con1, 5x1 + 3x2 + 3x3 <= 10)
@constraint(initial, con2, 7x1 - 2x2 - 2x3 >= 5)

optimize!(initial)

if termination_status(initial) == MOI.OPTIMAL
    println("Optimal solution found")

    println("Variable values:")
    @printf "x1: %0.3f\n" value.(x1)
    @printf "x2: %0.3f\n" value.(x2)
    @printf "x3: %0.3f\n" value.(x3)

    @printf "\nObjective value: %0.3f\n\n" objective_value(initial)

end
