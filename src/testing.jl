include("types.jl")
include("io.jl")
using BenchmarkTools, Dates

n = parse(Int64,ARGS[1])
f = parse(Float64,ARGS[2])
l = Int(ceil(n*f))
suc = [Agent(suceptible) for i in 1:l]
inf = [Agent(infected) for i in l+1:n]
N = Network(n,vcat(suc,inf),watts_strogatz(n,parse(Int64,ARGS[3]),0.5))

#=
N2 = Network(MutAgent,n)
N3 = MutNetwork(Agent,n)
N4 = MutNetwork(MutAgent,n)
@benchmark simpleEvolve(rand(1:n),N)
@benchmark simpleEvolve(rand(1:n),N2)
@benchmark simpleEvolve!(rand(1:n),N)
@benchmark simpleEvolve!(rand(1:n),N2)
@benchmark evolve(rand(1:n),N)
@benchmark evolve(rand(1:n),N2)
@benchmark evolve!(rand(1:n),N)
@benchmark evolve!(rand(1:n),N2)

@benchmark advanceParallel!(N,simpleEvolve)
@benchmark advanceParallel!(N2,simpleEvolve)
@benchmark advanceSequential!(N,simpleEvolve!)
@benchmark advanceSequential!(N2,simpleEvolve!)
@benchmark advanceSequentialRandom!(N,simpleEvolve!)
@benchmark advanceSequentialRandom!(N2,simpleEvolve!)

@benchmark advanceParallel!(N,evolve)
@benchmark advanceParallel!(N2,evolve)
@benchmark advanceParallel!(N3,evolve)
@benchmark advanceParallel!(N4,evolve)
@benchmark advanceSequential!(N,evolve!)
@benchmark advanceSequential!(N2,evolve!)
@benchmark advanceSequentialRandom!(N,evolve!)
@benchmark advanceSequentialRandom!(N2,evolve!)


@btime res = basicSimulation(N,1000,advanceParallel!,evolve)
@btime res = basicSimulation(N2,1000,advanceParallel!,evolve)
@btime res = basicSimulation(N3,1000,advanceParallel!,evolve)
@btime res = basicSimulation(N4,1000,advanceParallel!,evolve)

=#
main_path = joinpath("..","outputs",Dates.format(Dates.now(),"dd-mm-YYYY_HH-MM"))
mkdir(main_path)
writeAgents(joinpath(main_path,"agents.csv"),N)
writeNetwork(joinpath(main_path,"network.graphml"),N)
@time res = basicSimulation(N,parse(Int64,ARGS[4]),advanceParallel!,(i,N)->evolve(i,N,i_tmin=15,r_tmin=150))
writeSimulation(joinpath(main_path,"simulation.csv"),res)