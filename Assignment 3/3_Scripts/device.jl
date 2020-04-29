using JuMP, Gurobi, Printf

T = collect(1:12) #Time periods (Months)
I = collect(1:2) #Machines

#Demand per month
D = [
    707000,
    753000,
    724000,
    784000,
    699000,
    543000,
    564000,
    522000,
    693000,
    743000,
    760000,
    731000,
]

# Units
# 1 - Fast machine
# 2 - Slow machine

#Production cost per unit
c = [4, 2]

#Max capacity per month (given in units)
K = [400000, 650000]
