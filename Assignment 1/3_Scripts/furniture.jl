#Import packages
using JuMP
using Gurobi
using Printf
using MathOptFormat
using CSV

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

#Declare Gurobi model
model_furniture = Model(with_optimizer(Gurobi.Optimizer))

# Variable definition
@variable(model_furniture, 0<=b[i in I], Bin) # Build at location i
@variable(model_furniture, 0<=c[i in I, l in L], Bin) # Assign level to location i
@variable(model_furniture, 0<=a[i in I, m in M], Bin) # Assign market m to location i

# Objective function

# Assignment of capacity level
@constraint(model_furniture, capacitylevel[i in I], b[i] == sum(c[i,l] for l in L))
# Assignment of markets
@constraint(model_furniture, marketassignment[i in I], length(M)*b[i] >= sum(a[i,m] for m in M))
@constraint(model_furniture, onemarketperlocation[m in M], sum(a[i,m] for i in I) == 1)
# Distance between Locations
@constraint(model_furniture, dlocations[i in I, j in I; i!=j], d_location[i][j]*b[i] >= D)
