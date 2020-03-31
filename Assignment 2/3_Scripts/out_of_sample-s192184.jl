# Author:           Jorge Montalvo Arvizu
# Student number:   s192184

# Import packages
using JuMP
using Gurobi
using Printf
using MathOptFormat
using CSV
using DataFrames
using Plots
gr()

# Areas
I_names = ["zip2000","zip2800","zip7400","zip8900"]
I = collect(1:4)
# Samples
Samples = collect(1:100)

# Initial price in DKK/m2 in area i, access by p_init[i]
p_init = [42371,32979,15337,14192]

# Budget
B = 25000000

#Sample price in DKK/m2 in area i and sample s
#Reads price data from scenarios.csv file
#Access price by calling p[i,s]
df_p = CSV.read("samples.csv", delim=";")
array_p = Array(df_p)
p = zeros(Float64,length(I),length(Samples))
for i=1:size(array_p,1)
    p[Int(array_p[i,2]),Int(array_p[i,1])]=array_p[i,3]
end

#First stage solution for stochastic model, access by index i for area
solution_stochastic = [5 253 1050 24]

#First stage solution for expected value model, access by index i for area
solution_expected = [8 724 28 25]

# Initialize results vectors to preallocate memory
future_stochastic = Vector{Float64}(undef,length(Samples))
future_expected = Vector{Float64}(undef,length(Samples))
gain_stochastic = Vector{Float64}(undef,length(Samples))
gain_expected = Vector{Float64}(undef,length(Samples))

## Results

# Calculate investment cost
investment_stochastic = (solution_stochastic*p_init)[1]
investment_expected = (solution_expected*p_init)[1]

# Caculate future value and financial gain per model per sample
for s in Samples
    future_stochastic[s] = (solution_stochastic*p[:,s])[1]
    future_expected[s] = (solution_expected*p[:,s])[1]
    gain_stochastic[s] = future_stochastic[s] - investment_stochastic
    gain_expected[s] = future_expected[s] - investment_expected
end

# Results to DataFrame
df = DataFrame(
    SampleID = Samples,
    StochasticSolution = gain_stochastic,
    ExpectedValueSolution = gain_expected
)

# Write to csv file
CSV.write("sample-solutions-s192184.csv", df)

## Data Visualization

# Plot both models
plot([df.ExpectedValueSolution df.StochasticSolution], w=2, labels=permutedims(names(df)[2:3]))
xaxis!("Samples")
yaxis!("Financial gain [DKK]")
title!("Stochastic vs. Expected Value solution")

# Histogram to see distribution
histogram([df.ExpectedValueSolution df.StochasticSolution], nbins=20, labels=permutedims(names(df)[2:3]))
