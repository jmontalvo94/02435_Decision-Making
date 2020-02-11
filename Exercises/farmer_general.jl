#Import packages
using JuMP
using Gurobi
using Printf
# Install by running
# import Pkg
# Pkg.add("MathOptFormat")
# on the commandline
using MathOptFormat

#Sets
scenarios = [1,2,3]
plants = [1,2,3] # 1=wheat, 2=corn, 3=sugarbeets
price_levels = [1,2]
#Parameters
acres = 500
cost_per_acre = [150,230,260]
demand = [200,240,0]
purchase_price = [238,210,0]
sales_price_level = [[170,0],[150,0],[36,10]] #first index = plant, second index = price level
sales_ub_level = [[0,1500,1500],[0,1800,1800],[0,6000,12000]] #first index = plant, second index = price_level-1
plant_yield = [[2.0,2.5,3.0], [2.4,3.0,3.6], [16.0,20.0,24.0]] #first index = plant, second index = scenario
prob = [0.3,0.5,0.2]
max_purchase_amount = [200,240,0]

#Declare Gurobi model
model_farmer_stochastic = Model(with_optimizer(Gurobi.Optimizer))

#Definition of variables with lower bound 0
@variable(model_farmer_stochastic, 0<=x[p in plants])
@variable(model_farmer_stochastic, 0<=y[p in plants,s in scenarios])
@variable(model_farmer_stochastic, 0<=z[p in plants,i in price_levels, s in scenarios])

#Maximize profit
@objective(model_farmer_stochastic, Max,
        sum(-1*cost_per_acre[p]*x[p] for p in plants)
        -sum(prob[s]*purchase_price[p]*y[p,s] for p in plants for s in scenarios)
        +sum(prob[s]*sales_price_level[p][i]*z[p,i,s] for p in plants for i in price_levels for s in scenarios))
#Acres restriction
@constraint(model_farmer_stochastic, acres_constraint, sum(x[p] for p in plants) <= acres)
#Yield, buying and selling
@constraint(model_farmer_stochastic, yield_constraint[p in plants, s in scenarios],
        plant_yield[p][s]*x[p] + y[p,s] - sum(z[p,i,s] for i in price_levels) >= demand[p])
#Maximum at price level
@constraint(model_farmer_stochastic, price_level_constraint[p in plants, s in scenarios, i in price_levels],
        z[p,i,s] <= sales_ub_level[p][i+1]-sales_ub_level[p][i])
#Maximum purchase amount
@constraint(model_farmer_stochastic, max_amount_constraint[p in plants, s in scenarios],
        y[p,s] <= max_purchase_amount[p])

#Output model to an LP file for debugging
lp_model = MathOptFormat.LP.Model()
MOI.copy_to(lp_model, backend(model_farmer_stochastic))
MOI.write_to_file(lp_model, "farmer_model.lp")


optimize!(model_farmer_stochastic)

if termination_status(model_farmer_stochastic) == MOI.OPTIMAL
    println("Optimal solution found")

    println("Variable values:")
    for p in plants
        @printf("x%i: %0.3f\n", p, value.(x[p]))
    end

    for p in plants
        println()
        for s in scenarios
            println("Scenario" , s)
            @printf("y%i%i: %0.3f\n",p,s, value.(y[p,s]))
            for i in price_levels
                @printf("z%i%i%i: %0.3f\n",p,s,i, value.(z[p,i,s]))
            end
            println()
        end
    end

    @printf "\nObjective value: %0.3f\n\n" objective_value(model_farmer_stochastic)

else
    error("No solution.")
end
