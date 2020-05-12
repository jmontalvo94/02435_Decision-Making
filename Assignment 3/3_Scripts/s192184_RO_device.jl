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

# Efficiency of machine 2 (ignore η1 since it is 1)
η_bar2 = 0.7
η_dev2 = 0.1

device = Model(with_optimizer(Gurobi.Optimizer))

# Definition of variables with lower bound 0
@variable(device, p[i in I, t in T] >= 0)

@objective(device, Min, sum(sum(c[i]*p[i, t] for i in I) for t in T))

@constraint(device, capacity[i in I, t in T], p[i, t] <= K[i])
@constraint(device, demand[t in T], p[1, t] + p[2, t]*η_bar2 - p[2, t]*η_dev2 >= D[t])
optimize!(device)

if termination_status(device) == MOI.OPTIMAL
    println("Optimal solution found!")
    @printf "\nProduction cost: € %0.1f [EUR]\n" objective_value(device)
    println("\nProduction quantity:")
    for i in I
        for t in T
            @printf "p[%i, %i]: %0.1f [units]\n" i t value.(p)[i, t]
        end
    end
end
