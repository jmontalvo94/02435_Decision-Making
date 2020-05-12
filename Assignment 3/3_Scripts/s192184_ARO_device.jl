using JuMP, Gurobi, Printf

T = collect(1:12) #Time periods (Months)
I = collect(1:3) #Machines

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
# 3 - Extra capacity from machine 2

#Production cost per unit
c = [4, 2, 3]

#Max capacity per month (given in units)
K = [400000, 650000, 200000]

# Efficiency of machine 2 (ignore η1 since it is 1)
η_bar2 = 0.7
η_dev2 = 0.1
η_3 = 0.8

device = Model(with_optimizer(Gurobi.Optimizer))

# Definition of variables with lower bound 0
@variable(device, p[i in I, t in T] >= 0)
@variable(device, β[t in T] >= 0)
@variable(device, p_0[t in T] >= 0)
@variable(device, Q[t in T] >= 0)

@objective(device, Min, sum(sum(c[1]*p[1, t] + c[2]*p[2, t]) + β[t] for t in T))

@constraint(device, capacity[i in I, t in T], p[i, t] <= K[i])
@constraint(
    device,
    demand[t in T],
    p[1, t] + p[2, t]*η_bar2 + p_0[t]*η_3 - p[2, t]*η_dev2 - η_3*Q[t] >= D[t]
)
@constraint(device, prod3[t in T], p[3, t] == p_0[t] + Q[t])
@constraint(device, cost3[t in T], c[3]*p[3, t] <= β[t])
@constraint(device, minprod3[t in T], p_0[t] - Q[t] >= 0)


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
