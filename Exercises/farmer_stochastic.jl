#Import packages
using JuMP
using Gurobi
using Printf
# Install by running
# import Pkg
# Pkg.add("MathOptFormat")
# on the commandline
using MathOptFormat

#Yield parameter
scenarios = [1,2,3]
yield_wheat = [2.0,2.5,3.0]
yield_corn = [2.4,3.0,3.6]
yield_sugarbeets = [16.0,20.0,24.0]
prob = [0.3,0.5,0.2]

#Declare Gurobi model
model_farmer_stochastic = Model(with_optimizer(Gurobi.Optimizer))

#Definition of variables with lower bound 0
@variable(model_farmer_stochastic, 0<=x_w)
@variable(model_farmer_stochastic, 0<=x_c)
@variable(model_farmer_stochastic, 0<=x_s)
@variable(model_farmer_stochastic, 0<=y_w[s in scenarios])
@variable(model_farmer_stochastic, 0<=y_c[s in scenarios])
@variable(model_farmer_stochastic, 0<=z_w[s in scenarios])
@variable(model_farmer_stochastic, 0<=z_c[s in scenarios])
@variable(model_farmer_stochastic, 0<=z_s[s in scenarios])
@variable(model_farmer_stochastic, 0<=v_s[s in scenarios])

println(scenarios)
for s in scenarios
    print("scenario ", s)
    println(" prob" , prob[s])
end

#Maximize profit
@objective(model_farmer_stochastic, Max, -150x_w - 230x_c - 260x_s + sum(prob[s] * (170*z_w[s] + 150*z_c[s]  + 36*z_s[s]  + 10*v_s[s]  - 238*y_w[s] - 210*y_c[s]) for s in scenarios))
#Acres restriction
@constraint(model_farmer_stochastic, acres, x_w + x_c + x_s <= 500)
#Yield, buying and selling of wheat
@constraint(model_farmer_stochastic, wheat[s in scenarios], yield_wheat[s]*x_w + y_w[s] - z_w[s] >= 200)
#Yield, buying and selling of corn
@constraint(model_farmer_stochastic, corn[s in scenarios], yield_corn[s]*x_c + y_c[s] - z_c[s] >= 240)
#Yield, buying and selling of sugar beets
@constraint(model_farmer_stochastic, sugarbeets[s in scenarios], z_s[s] + v_s[s] - yield_sugarbeets[s]*x_s <= 0)
#Maximum of 6000t at high price
@constraint(model_farmer_stochastic, highprice[s in scenarios], z_s[s] <= 6000)


optimize!(model_farmer_stochastic)

#Output model to an LP file for debugging
lp_model = MathOptFormat.LP.Model()
MOI.copy_to(lp_model, backend(model_farmer_stochastic))
MOI.write_to_file(lp_model, "farmer_model.lp")

if termination_status(model_farmer_stochastic) == MOI.OPTIMAL
    println("Optimal solution found")

    println("Variable values:")
    @printf "x_w: %0.3f\n" value.(x_w)
    @printf "x_c: %0.3f\n" value.(x_c)
    @printf "x_s: %0.3f\n" value.(x_s)
    println()
    for s in scenarios
        println("Scenario" , s)
        @printf("y_w%i: %0.3f\n",s, value.(y_w[s]))
        @printf("y_c%i: %0.3f\n",s, value.(y_c[s]))
        @printf("z_w%i: %0.3f\n",s, value.(z_w[s]))
        @printf("z_c%i: %0.3f\n",s, value.(z_c[s]))
        @printf("z_s%i: %0.3f\n",s, value.(z_s[s]))
        @printf("v_s%i: %0.3f\n",s, value.(v_s[s]))
        println()
    end

    @printf "\nObjective value: %0.3f\n\n" objective_value(model_farmer_stochastic)

else
    error("No solution.")
end
