#Import packages
using JuMP
using Gurobi
using Printf
using MathOptFormat

#Sets
scenarios = collect(1:3)
periods = collect(1:24)
chp_units = collect(1:1)
heat_units = collect(1:2) #Unit 1 = GB, Unit 2= WCB

#Electricity price forecast per hour and scenario
e = [[245.41,275.07,225.8], [260.13,232.31,226.09], [271.21,237.84,223.64],
[266.23,220.89,236.06], [237.97,219.62,290.58], [213.36,207.5,743.58], [196.1,206.61,892.55],
[187.7,236.36,785.16], [187.18,251.944,743.73], [188,256.5465,632.62], [205.55,259.4155,593.72],
[244.66,277.9105,453.12], [281.85,272.5395,639.68], [292.93,320.1595,484.84],
[284.3,301.4205,365.32], [290.92,279.928,560.33], [291.66,307.125,364.65],
[290.18,277.974,366.21], [290.99,290.35,334.38], [281.1,335.27,311.77],
[275.08,196.1,267.45], [259.31,187.7,232.71], [275.67,187.18,223.04], [294.79,188,219.25]]

#Heat demand forecast per hour and scenario
d = [[8.9,8.88,5.73],[8.7,9.08,7.24],[7.02,8.98,7.54],[7.02,9.28,7.54],[7.02,9.08,7.54],
[6.03,9.18,7.14],[6.13,9.08,7.14],[5.83,9.28,7.44],[5.73,7.42,7.34],[6.03,7.12,7.14],
[5.73,7.32,7.24],[7.14,8.56,7.54],[7.34,8.36,7.54],[7.34,8.36,7.14],[7.34,8.36,7.54],
[7.44,8.36,7.24],[7.54,8.36,5.93],[7.14,10.58,5.93],[7.24,10.28,5.93],[7.44,10.48,6.29],
[7.44,10.28,6.19],[7.54,10.18,6.39],[7.24,10.28,6.39],[7.34,10.18,6.59]]

#Scenario probabilities
prob = [0.5, 0.3125, 0.1875]

#Parameter CHP
chp_qmax = 10
chp_c = 600
chp_phi = 1.1

#Parameter Heat Units
qmax = [10, 4]
c = [420,250]

#Storage capacity
K = 7

#Declare Gurobi model
model_heat = Model(with_optimizer(Gurobi.Optimizer))

#Variable definition
@variable(model_heat, 0<=q_chp[j in chp_units, t in periods])   #Heat production for each CHP unit and period
@variable(model_heat, 0<=q_h[i in heat_units, t in periods, s in scenarios]) #Heat production for each unit, period and scenario
@variable(model_heat, 0<=s_in[t in periods, s in scenarios]) #Storage inflow per period and scenario
@variable(model_heat, 0<=s_out[t in periods, s in scenarios]) #Storage outflow per period and scenario
@variable(model_heat, 0<=s_level[t in periods, s in scenarios]) #Storage level per period and scenario

#Minimize expected cost
@objective(model_heat, Min,
        sum(chp_c*q_chp[j,t] for j in chp_units for t in periods)
        - sum(prob[s]*e[t][s]*(1.0/chp_phi)*q_chp[j,t] for j in chp_units for t in periods for s in scenarios)
        + sum(prob[s]*c[i]*q_h[i,t,s] for i in heat_units for t in periods for s in scenarios))

#Max CHP production
@constraint(model_heat, max_chp_production[j in chp_units, t in periods], q_chp[j,t] <= chp_qmax)

#Max heat unit production
@constraint(model_heat, max_heat_production[i in heat_units, t in periods, s in scenarios], q_h[i,t,s] <= qmax[i])

#Demand satisfaction
@constraint(model_heat, demand_satisfaction[t in periods, s in scenarios], sum(q_chp[j,t] for j in chp_units) +
                sum(q_h[i,t,s] for i in heat_units) - s_in[t,s] + s_out[t,s]== d[t][s])

#Storage balance
@constraint(model_heat, storage_balance[t in collect(2:24), s in scenarios], s_level[t,s]-s_level[t-1,s]-s_in[t,s]+s_out[t,s]==0)
@constraint(model_heat, storage_balance_init[s in scenarios], s_level[1,s]-s_in[1,s]+s_out[1,s]==0)
#Storage capacity
@constraint(model_heat, storage_capacity[t in periods, s in scenarios], s_level[t,s] <= K)




#Write model to an LP file for debugging
lp_model = MathOptFormat.LP.Model()
MOI.copy_to(lp_model, backend(model_heat))
MOI.write_to_file(lp_model, "heat_model.lp")


optimize!(model_heat)


if termination_status(model_heat) == MOI.OPTIMAL
    println("Optimal solution found")

    println("Heat production:")
    println("t\tCHP\t\tGB\t\t\tWCB\t\tStorage\t\t")
    println("\t\t1\t2\t3\t1\t2\t3\t1\t2\t3")
    for t in periods
        output_line = "$t\t"
        for j in chp_units
            output_line *= "$(@sprintf("%.2f",(value.(q_chp[j,t]))))\t"
        end

        for j in heat_units
            for s in scenarios
                output_line *= "$(@sprintf("%.2f",value.(q_h[j,t,s])))\t"
            end
        end

        for s in scenarios
            output_line *= "$(@sprintf("%.2f",value.(s_level[t,s])))\t"
        end

        output_line *="\n"
        print(output_line)
    end

    @printf "\nObjective value: %0.3f\n\n" objective_value(model_heat
    )


else
    error("No solution.")
end
