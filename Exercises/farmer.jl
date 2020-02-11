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
yield_wheat = 3.0
yield_corn = 3.6
yield_sugarbeets = 24.0

#Declare Gurobi model
model_farmer = Model(with_optimizer(Gurobi.Optimizer))

#Definition of variables with lower bound 0
@variable(model_farmer, 0<=x_w)
@variable(model_farmer, 0<=x_c)
@variable(model_farmer, 0<=x_s)
@variable(model_farmer, 0<=y_w)
@variable(model_farmer, 0<=y_c)
@variable(model_farmer, 0<=z_w)
@variable(model_farmer, 0<=z_c)
@variable(model_farmer, 0<=z_s)
@variable(model_farmer, 0<=v_s)

#Maximize profit
@objective(model_farmer, Max, 170z_w + 150z_c + 36z_s + 10v_s - 150x_w - 230x_c - 260x_s - 238y_w - 210y_c)
#Acres restriction
@constraint(model_farmer, acres, x_w + x_c + x_s <= 500)
#Yield, buying and selling of wheat
@constraint(model_farmer, wheat, yield_wheat*x_w + y_w - z_w >= 200)
#Yield, buying and selling of corn
@constraint(model_farmer, corn, yield_corn*x_c + y_c - z_c >= 240)
#Yield, buying and selling of sugar beets
@constraint(model_farmer, sugarbeets, z_s + v_s - yield_sugarbeets*x_s <= 0)
#Maximum of 6000t at high price
@constraint(model_farmer, highprice, z_s <= 6000)


optimize!(model_farmer)

#Output model to an LP file for debugging
lp_model = MathOptFormat.LP.Model()
MOI.copy_to(lp_model, backend(model_farmer))
MOI.write_to_file(lp_model, "farmer_model.lp")

if termination_status(model_farmer) == MOI.OPTIMAL
    println("Optimal solution found")

    println("Variable values:")
    @printf "x_w: %0.3f\n" value.(x_w)
    @printf "x_c: %0.3f\n" value.(x_c)
    @printf "x_s: %0.3f\n" value.(x_s)
    @printf "y_w: %0.3f\n" value.(y_w)
    @printf "y_c: %0.3f\n" value.(y_c)
    @printf "z_w: %0.3f\n" value.(z_w)
    @printf "z_c: %0.3f\n" value.(z_c)
    @printf "z_s: %0.3f\n" value.(z_s)
    @printf "v_s: %0.3f\n" value.(v_s)

    @printf "\nObjective value: %0.3f\n\n" objective_value(model_farmer)

else
    error("No solution.")
end
