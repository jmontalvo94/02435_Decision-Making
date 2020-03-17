#Import packages
using JuMP
using Gurobi
using Printf
using MathOptFormat
using CSV

#Areas
I_names = ["zip2000","zip2800","zip7400","zip8900"]
I = collect(1:4)
#Scenarios
S = collect(1:12)



# Initial price in DKK/m2 in area i, access by p_init[i]
p_init = [42371,32979,15337,14192]

#Budget
B = 25000000

#Forecasted price in DKK/m2 in area i and scenario s
#Reads price data from scenarios.csv file
#Access price by calling p[i,s]
df_p = CSV.read("scenarios.csv", delim=";")
array_p = Array(df_p)
p = zeros(Float32,length(I),length(S))
for i=1:size(array_p,1)
    p[Int(array_p[i,2]),Int(array_p[i,1])]=array_p[i,3]
end

#Probabilities
prob = [0.09 0.13 0.08 0.10 0.08 0.06 0.07 0.10 0.05 0.07 0.12 0.05]

beta = 0.2
alpha = 0.9
