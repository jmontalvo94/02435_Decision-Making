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
