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

model_parcel = Model(with_optimizer(Gurobi.Optimizer))

#Variable definition
@variable(model_parcel, 0<=y[w in W, d in D], Bin) #Assignment warehouse -> district
@variable(model_parcel, 0<=z[w in W, t in TH, s in S], Int) #Number of drivers hired at period t in scenario s at warehouse w
@variable(model_parcel, 0<=m[t in TD, s in S]) #Missing demand

#Objective
@objective(model_parcel, Min, sum(c_T[w][d]*y[w,d] for w in W for d in D)
    + sum(prob[s]*c_P*z[w,t,s] for w in W for s in S for t in TH)
    + sum(prob[s]*phi*m[t,s] for t in TD for s in S))

# Assignment warehouse and district
@constraint(model_parcel, assignment[d in D], sum(y[w,d] for w in W) ==1)

# Demand fulfillment
@constraint(model_parcel, demand[w in W, t in TD, s in S],
        H*z[w, t-1, s] >= sum(A[d,t,s]*y[w,d] for d in D) - m[t,s])

# Maximum number of drivers
@constraint(model_parcel, max_drivers[w in W, t in TH, s in S],
        z[w,t,s] <= K[w])

# Reallocation of drivers
@constraint(model_parcel, reallcoation[t in TH, s in S; t>1],
        sum(z[w,t-1,s] for w in W) <= sum(z[w,t,s] for w in W))

# Non-anticipativity z variables
@constraint(model_parcel, non_anticipativity_z[w in W, t in TH, s in S, omega in Omega[s][t]],
        z[w,t,s] == z[w,t,omega])

# Non-anticipativity m variables
@constraint(model_parcel, non_anticipativity_m[t in TD, s in S, omega in Omega[s][t]],
        m[t,s] == m[t,omega])

#Write model to an LP file for debugging
lp_model = MathOptFormat.LP.Model()
MOI.copy_to(lp_model, backend(model_parcel))
MOI.write_to_file(lp_model, "model_parcel.lp")


optimize!(model_parcel)


if termination_status(model_parcel) == MOI.OPTIMAL
    println("Optimal solution found")

    println("\n")
    for w in W

           output_line = "Warehouse $w:\t"

           for d in D
                if (value.(y[w,d])>=0.99)
                    output_line *= "$d,"
                end
           end
           println(output_line)

           println("Drivers at warehouse $w:")
           for t in TH

               for s in S
                    println("W$w\tT$t\tS$s:\t$(value.(z[w,t,s]))")
                    end
                end







   end
    println("Missing demand")
   for t in TD
       for s in S
           if value.(m[t,s]) >0.0000000001
               println("T$t,S$s:\t$(value.(m[t,s]))")
           end
       end
   end

    @printf "Objective:%0.3f" objective_value(model_parcel)


else
    error("No solution.")
end
