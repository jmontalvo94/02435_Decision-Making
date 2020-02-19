#Import packages
using JuMP
using Gurobi
using Printf
using MathOptFormat

#Sets
scenarios = collect(1:3)
periods = collect(1:24)
units_chp = collect(1:1)
units_heat = collect(1:2) #Unit 1 = GB, Unit 2= WCB

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
[7.44,8.36,7.24],[7.54,8.36,5.93],[7.14,10.58,5.93],[7.24,10.28,5.93],[7.44,10.48,6.29],[7.44,10.28,6.19],[7.54,10.18,6.39],[7.24,10.28,6.39],[7.34,10.18,6.59]]

#Scenario probabilities
π = [0.5, 0.3125, 0.1875]

#Parameter CHP
qmax_chp = 10
c_chp = 600
ϕ_chp = 1.1

#Parameter Heat Units
qmax_heat = [10, 4]
c_heat = [420,250]


#Declare Gurobi model
model_heat = Model(with_optimizer(Gurobi.Optimizer))

@variable(model_heat, 0<=p_chp[i in units_chp, t in periods]) #Heat production for chp over period and scenario
@variable(model_heat, 0<=p_heat[i in units_heat, t in periods, s in scenarios]) #Heat production for each unit, period and scenario

#@variable(model_heat, 0<=s_in[t in periods, s in scenarios]) #Storage inflow per period and scenario
#@variable(model_heat, 0<=s_out[t in periods, s in scenarios]) #Storage outflow per period and scenario
#@variable(model_heat, 0<=s_level[t in periods, s in scenarios]) #Storage level per period and scenario
#@variable(model_heat, 0<=q_miss[t in periods, s in scenarios]) #Missing heat

#@objective(model_heat, Min, sum(c_chp[j]*p_chp[j,t] for j in units_chp for t in periods)-sum(pi[s]*e[t,s]*(1/ϕ_chp)*p_chp[j,t] for j in units_chp for t in periods for s in scenarios)+sum(pi[s]*c_heat[i,t]*p_heat[i,t,s] for i in units_heat for t in periods for s in scenarios))
#@objective(model_heat, Min,sum(c_chp[j]*p_chp[j,t] - pi[s]*e[t,s]*(1/ϕ_chp)*p_chp[j,t] + pi[s]*c_heat[i,t]*p_heat[i,t,s] for i in units_heat for j in units_chp for t in periods for s in scenarios))

function Σ(x)
	return sum(x)
end

@objective(model_heat, Min, Σ( Σ(c_chp[j]*p_chp[j,t] - Σ(π[s]*e[t][s]*(1/ϕ_chp)*p_chp[j,t] for s in scenarios) for j in units_chp) + Σ(π[s]*c_heat[i]*p_heat[i,t,s] for i in units_heat for s in scenarios) for t in periods))

#Max heat unit production
@constraint(model_heat, max_heat_production[i in heat_units, t in periods], q_h[i,t] <= qmax[i])

#Demand satisfaction
@constraint(model_heat, demand_satisfaction[t in periods, s in scenarios],
                sum(q_h[i,t] for i in heat_units) - s_in[t,s] + s_out[t,s]== d[t][s] - q_miss[t,s])

#Storage balance
#@constraint(model_heat, storage_balance[t in collect(2:24), s in scenarios], s_level[t,s]-s_level[t-1,s]-s_in[t,s]+s_out[t,s]==0)
#@constraint(model_heat, storage_balance_init[s in scenarios], s_level[1,s]-s_in[1,s]+s_out[1,s]==0)
#Storage capacity
#@constraint(model_heat, storage_capacity[t in periods, s in scenarios], s_level[t,s] <= K)

#Write model to an LP file for debugging
lp_model = MathOptFormat.LP.Model()
MOI.copy_to(lp_model, backend(model_heat))
MOI.write_to_file(lp_model, "heat_model.lp")


optimize!(model_heat)


if termination_status(model_heat) == MOI.OPTIMAL


	#ADD ADDITIONAL OUTPUT HERE


    @printf "\nObjective value: %0.3f\n\n" objective_value(model_heat)


else
    error("No solution.")
end
