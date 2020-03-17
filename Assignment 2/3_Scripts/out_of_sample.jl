#Import packages
using JuMP
using Gurobi
using Printf
using MathOptFormat
using CSV

#Areas
I_names = ["zip2000","zip2800","zip7400","zip8900"]
I = collect(1:4)
#Samples
Samples = collect(1:100)



# Initial price in DKK/m2 in area i, access by p_init[i]
p_init = [42371,32979,15337,14192]

#Budget
B = 25000000

#Sample price in DKK/m2 in area i and sample s
#Reads price data from scenarios.csv file
#Access price by calling p[i,s]
df_p = CSV.read("samples.csv", delim=";")
array_p = Array(df_p)
p = zeros(Float32,length(I),length(Samples))
for i=1:size(array_p,1)
    p[Int(array_p[i,2]),Int(array_p[i,1])]=array_p[i,3]
end


#First stage solution for stochastic model, access by index i for area
solution_stochastic = [5 253 1050 24]

#First stage solution for expectec value model, access by index i for area
solution_expected = [8 724 28 25]
