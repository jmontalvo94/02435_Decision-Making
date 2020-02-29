#Import packages
using JuMP
using Gurobi
using Printf
using MathOptFormat
using CSV

#Warehouses
W = collect(1:3)
#Districts
D = collect(1:10)
#Time periods
T = collect(1:3)
#Scenarios
S = collect(1:4)
#Hiring periods
TH = collect(1:2)
#Delvivery periods
TD = collect(2:3)

#Demand data
#Read demand data from demand.csv file
#Access demand by calling A[d,t,s]
df_a = CSV.read("demand.csv", delim=",")
array_a = Array(df_a)
A = zeros(Float32,length(D),length(T),length(S))
for i=1:size(array_a,1)
    A[convert(Int64,array_a[i,1]),convert(Int64,array_a[i,2]),convert(Int64,array_a[i,3])]=array_a[i,4]
end

#Distance-based transportation cost for each warehouse w and district d
#Call by c_T[w,d]
c_T = [[45000,50000,152500,242500,162500,200000,325000,205000,10000,42500],
[202500,42500,25000,25000,20000,132500,362500,422500,62500,245000],
[320000,225000,302500,242500,112500,25000,50000,80000,85000,92500]]

#Maximum number of drivers per warehouse
K = [9,12,15]

#Personnel cost
c_P = 30000

#Working hours per year
H = 2080

#Penalty costs
phi = 100000

#Probability per scenario
prob = [0.2925,0.1575,0.22,0.33]

#Scenario subsets for non-anticipativity constraints
#Access with Omega[s][t] returns an array with all scenarios that should be considered with scenario s in period t
Omega = Dict(1 => Dict(1 => [1,2,3,4], 2 => [1,2], 3 => [1]),
    2 => Dict(1 => [1,2,3,4], 2 => [1,2], 3 => [2]),
    3 => Dict(1 => [1,2,3,4], 2 => [3,4], 3 => [3]),
    4 => Dict(1 => [1,2,3,4], 2 => [3,4], 3 => [4]))

    #Declare Gurobi model
model_parcel = Model(with_optimizer(Gurobi.Optimizer))

#Variable definition
@variable(model_parcel, 0 <= q_chp[j in chp_units, t in periods])   #Heat production for each CHP unit and period
@variable(model_parcel, 0 <= q_h[i in heat_units, t in periods, s in scenarios]) #Heat production for each unit, period and scenario

#Minimize expected cost
@objective(
    model_heat,
    Min,
    sum(chp_c * q_chp[j, t] for j in chp_units for t in periods) - sum(
        prob[s] * e[t][s] * (1.0 / chp_phi) * q_chp[j, t] for j in chp_units
        for t in periods
        for s in scenarios
    ) + sum(
        prob[s] * c[i] * q_h[i, t, s] for i in heat_units for t in periods
        for s in scenarios
    )
)

#Max CHP production
@constraint(
    model_heat,
    max_chp_production[j in chp_units, t in periods],
    q_chp[j, t] <= chp_qmax
)

#Max heat unit production
@constraint(
    model_heat,
    max_heat_production[i in heat_units, t in periods, s in scenarios],
    q_h[i, t, s] <= qmax[i]
)

#Demand satisfaction
@constraint(
    model_heat,
    demand_satisfaction[t in periods, s in scenarios],
    sum(q_chp[j, t] for j in chp_units) + sum(q_h[i, t, s] for i in heat_units) == d[t][s]
)


#Write model to an LP file for debugging
lp_model = MathOptFormat.LP.Model()
MOI.copy_to(lp_model, backend(model_heat))
MOI.write_to_file(lp_model, "heat_model.lp")


optimize!(model_heat)


if termination_status(model_heat) == MOI.OPTIMAL
    println("Optimal solution found")

    println("Heat production:")
    println("t\tCHP\t\tGB\t\t\tWCB\t")
    println("\t\t1\t2\t3\t1\t2\t3")
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

        output_line *= "\n"
        print(output_line)
    end

    @printf "\nObjective value: %0.3f\n\n" objective_value(model_heat)


else
    error("No solution.")
end
