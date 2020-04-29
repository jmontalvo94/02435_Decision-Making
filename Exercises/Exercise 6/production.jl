#Import packages
using JuMP
using Gurobi
using Printf
using MathOptFormat
using CSV

#Products
P = collect(1:10)
#Machine types
M = collect(1:4)

#Parameter indicating whether product p can be produced on machine type m
#Access by a[p][m], if 1, production is possible, 0, otherwise
a = [[1	1	0	0], [1	1	0	0],[0	1	1	0],[0	0	1	1],
[0	0	1	1],[1	1	1	1],[0	0	0	1],[1	1	0	1],
[1	1	0	0],[0	1	1	0]]

#Cost of buying one machine of type m, access c_m[m] [EUR]
c_m = [10000 50000 30000 75000]

#Available production time for each machine of type m, access by t[m] [hours]
t_m = [2080 2080 2080 2080]

#Production cost per unit of product, access c_p[p] [EUR]
c_p = [138 181 149 177 187 131 149 178 147 189]

#Target production of product p (demand), access d[p] [units]
d = [5844 9313 5725 8511 9465 27866 28396 27394 27590 27612]

#Expected production time for product p independent of machine type [hours]
t_bar =  [0.2 0.2 0.1 0.3 0.2 0.4 0.15 0.6 0.4 0.6]

#Possible deviation from expected production for product p [hours]
t_dev = [0.04 0.05 0.02 0.06 0.04 0.08 0.03 0.12 0.08 0.14]

#Budget of uncertainty for machine type m
Gamma = [0.0 0.0 0.0 0.0]
for m in M
        Gamma[m] = sum(a[p][m] for p in P) * 0.3
end

model_production = Model(with_optimizer(Gurobi.Optimizer))

#Variable definition
@variable(model_production, 0<=x[p in P, m in M]) #Units of product p produced on machine type m
@variable(model_production, 0<=y[m in M],Int) #Number of machines of machine type m
#ADD FURTHER VARIABLES HERE


#Minimize production cost
@objective(model_production, Min, sum(c_m[m]*y[m] for m in M) + sum(c_p[p]*x[p,m] for p in P for m in M))

#Fulfill demand
@constraint(model_production, demand[p in P], sum(x[p,m] for m in M) >= d[p])

#Production time
#ADD MISSING CONSTRAINTS HERE


#Machine type compatibility, bigM = available production time / best case production time
@constraint(model_production, machines[m in M,p in P], x[p,m] <= a[p][m]*y[m]*ceil(t_m[m]/(t_bar[p]-t_dev[p])))

optimize!(model_production)


if termination_status(model_production) == MOI.OPTIMAL
    println("Optimal solution found")

    println("\n")
    for m in M
        println("Machine type $m: $(value.(y[m]))")
    end

    for p in P
        production = sum(value.(x[p,m]) for m in M)
        println("Production $p: $production")
    end
end
