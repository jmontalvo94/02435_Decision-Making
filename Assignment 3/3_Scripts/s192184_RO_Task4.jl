using JuMP, Gurobi, Printf

clearconsole()

Γ = 2

initial = Model(with_optimizer(Gurobi.Optimizer))

# Definition of variables with lower bound 0
@variable(initial, -2<=x1<=10)
@variable(initial, 0<=x2<=15)
@variable(initial, -10<=x3<=10)
@variable(initial, 0<=y1)
@variable(initial, 0<=y2)
@variable(initial, 0<=y3)
@variable(initial, 0<=λ)
@variable(initial, 0<=μ1)
@variable(initial, 0<=μ2)
@variable(initial, 0<=μ3)

@objective(initial, Max, 10x1+20*x2+15x3)

@constraint(initial, con1, 4.5x1 + 5.5x2 + 3x3 + Γ*λ + μ1 + μ2 + μ3 <= 10)
@constraint(initial, con2, 7x1 - 2x2 - 2x3 >= 5)
@constraint(initial, con3, λ + μ1 >= 3.5y1)
@constraint(initial, con4, λ + μ2 >= 3.5y2)
@constraint(initial, con5, λ + μ3 >= 2y3)
@constraint(initial, con6, - y1 <= x1)
@constraint(initial, con7, x1 <= y1)
@constraint(initial, con8, - y2 <= x2)
@constraint(initial, con9, x2 <= y2)
@constraint(initial, con10, - y3 <= x3)
@constraint(initial, con11, x3 <= y3)

optimize!(initial)

if termination_status(initial) == MOI.OPTIMAL
    println("Optimal solution found")

    println("Variable values:")
    @printf "x1: %0.3f\n" value.(x1)
    @printf "x2: %0.3f\n" value.(x2)
    @printf "x3: %0.3f\n" value.(x3)

    @printf "\nObjective value: %0.3f\n\n" objective_value(initial)

end
