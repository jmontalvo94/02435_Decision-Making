#Import packages
using JuMP
using Gurobi
using Printf
using MathOptFormat
using CSV
using Printf

#Locations
I = collect(1:5)
#Capacity level
L = collect(1:4)
#Markets
M = collect(1:15)
#Furniture products
F = collect(1:6)
#Time periods
T = collect(1:10)
#Scenarios
S = collect(1:5)


#Demand data
#Read demand data from demand.csv file
#Access demand by calling b[m,f,t,s]
df_b = CSV.read("demand.csv", delim=",")
array_b = Array(df_b)
b = zeros(Int,length(M),length(F),length(T),length(S))
for i=1:size(array_b,1)
    b[array_b[i,1],array_b[i,2],array_b[i,3],array_b[i,4]]=array_b[i,5]
end

#Distance d_location[i][j] between locations
d_location = [[0,287.24,50.33,365.85,500.03],
[287.24,0,246.2,131.55,213.34],
[50.33,246.2,0,317.17,459.53],
[365.85,131.55,317.17,0,205.8],
[500.03,213.34,459.53,205.8,0]]

#Distance d_market[m][i] between market and location
d_market = [[616.85,335.27,571.24,265.27,155.8],
[475.93,305.51,461.39,410.98,299.45],
[623.42,336.27,582.07,305.36,123.98],
[382.46,611.06,393.31,622.04,812.03],
[754.14,520.22,730.99,572.78,377.21],
[282.45,325.13,296.99,455.6,469.9],
[249.23,158.67,198.91,140,331.49],
[576.89,454.74,573.26,566.08,449.64],
[186.96,293.62,152.4,298.48,487.65],
[654.54,447.24,604.24,317.42,390.37],
[656.54,547.46,656.56,658.78,536.15],
[443.03,642.79,488.84,761.99,815.49],
[577.53,386.87,561.43,476.39,326.26],
[443.21,622.56,439.83,605.96,807.16],
[205.88,379.23,191.76,389.01,577.48]]

#Production capacity per capacity level (values represent total capacity, not additional capacity)
k_production = [2000,4000,5000,8000]

#Storage capacity per capacity level (values represent total capacity, not additional capacity)
k_storage = [500,1000,2000,3000]

#Building cost per capacity level
c_building = [22.55000, 30.00000, 57.50000, 82.30000]

#Operational cost per location
c_operational = [2.00000, 6.00000, 3.00000, 5.00000, 4.50000]

#Transportation cost
c_transport = 0.00300

#Probability per scenario
prob = [0.15, 0.06,0.4,0.3,0.09]

#Minimum distance between locations
D = 150

bigM = maximum(b)*100

# Declare Gurobi model
model_furniture = Model(with_optimizer(Gurobi.Optimizer))

# Binary variables
@variable(model_furniture, 0<=build[i in I], Bin) # Build at location i
@variable(model_furniture, 0<=cap[i in I, l in L], Bin) # Assign level to location i
@variable(model_furniture, 0<=assignment[i in I, m in M], Bin) # Assign market m to location i
# Positive variables
@variable(model_furniture, 0<=s_in[f in F, i in I, t in T, s in S]) # Storage inflow
@variable(model_furniture, 0<=s_out[f in F, i in I, t in T, s in S]) # Storage outflow
@variable(model_furniture, 0<=s_level[f in F, i in I, t in T, s in S]) # Storage level
@variable(model_furniture, 0<=q_p[f in F, i in I, t in T, s in S]) # Produced units
@variable(model_furniture, 0<=q_t[f in F, i in I, j in I, t in T, s in S]) # Transported units
@variable(model_furniture, 0<=q_s[f in F, i in I, m in M, t in T, s in S]) # Supplied units

# Objective function
@objective(model_furniture, Min,
    sum(c_operational[i]*build[i]*length(T) for i in I)
    + sum(cap[i,l]*c_building[l] for i in I for l in L)
    + sum(prob[s]*c_transport*q_t[f,i,j,t,s]*d_location[i][j] for f in F for i in I for j in I for t in T for s in S)
    + sum(prob[s]*c_transport*q_s[f,i,m,t,s]*d_market[m][i] for f in F for i in I for m in M for t in T for s in S))

# Assignment of capacity level
@constraint(model_furniture, capacitylevel[i in I], build[i] == sum(cap[i,l] for l in L))
# Assignment of markets
@constraint(model_furniture, location_connection[i in I], sum(assignment[i,m] for m in M) <= length(M)*build[i])
@constraint(model_furniture, onemarketperlocation[m in M], sum(assignment[i,m] for i in I) == 1)
# Distance between locations
@constraint(model_furniture, distance_btw_locations[i in I, j in I; i!=j], d_location[i][j] - D * (-1+build[i]+build[j]) >= 0)
# Maximum production
@constraint(model_furniture, max_production[i in I, t in T, s in S], sum(q_p[f,i,t,s] for f in F) <= sum(cap[i,l]*k_production[l] for l in L))
# Maximum storage
@constraint(model_furniture, max_storage[i in I, t in T, s in S], sum(s_level[f,i,t,s] for f in F) <= sum(cap[i,l]*k_storage[l] for l in L))
# Location balance equation
@constraint(model_furniture, location_balance[f in F, i in I, t in T, s in S],
    sum(q_s[f,i,m,t,s] for m in M) == q_p[f,i,t,s] + s_out[f,i,t,s] - s_in[f,i,t,s]
    + sum(q_t[f,j,i,t,s] for j in I if j!=i) - sum(q_t[f,i,k,t,s] for k in I if k!=i))
# Market balance equation
@constraint(model_furniture, market_balance[f in F, i in I, t in T, s in S, m in M], q_s[f,i,m,t,s] == b[m,f,t,s]*assignment[i,m])
# Storage balance
@constraint(model_furniture, storage_balance[f in F, i in I, t in collect(2:10), s in S], s_level[f,i,t,s]-s_level[f,i,t-1,s]-s_in[f,i,t,s]+s_out[f,i,t,s]==0)
@constraint(model_furniture, storage_balance_init[f in F, i in I, s in S], s_level[f,i,1,s]-s_in[f,i,1,s]+s_out[f,i,1,s]==0)
# Limit transportation between opened locations only
@constraint(model_furniture, transport_btw_locations[f in F, i in I, j in I, t in T, s in S], q_t[f,i,j,t,s] <= bigM*build[i])

# Run model
optimize!(model_furniture)

# Print solution
if termination_status(model_furniture) == MOI.OPTIMAL
    for i in I
        state=nothing
        capacity="0"
        if (value.(build[i])==1)
            state="open"
        else
            state="not_open"
        end
        for l in L
            if (value.(cap[i,l])==1)
                capacity=string(l)
            end
        end
        println("Location:$i,$state,$capacity")
   end
   for m in M
       locationassigned=nothing
       for i in I
           if (round(value.(assignment[i,m]))==1.0)
               locationassigned = string(i)
           end
       end
       println("Market:$m, $locationassigned")
   end
    @printf "Objective:%f" objective_value(model_furniture)
else
    error("No solution.")
end
