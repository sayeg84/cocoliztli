include("evolution.jl")
include("io.jl")
using BenchmarkTools, Dates, Distributions, ArgParse

function model_p_i1(x::Number)::Float64
    f = Distributions.NegativeBinomial(20,0.45)
    return Distributions.pdf(f,x)
end
function model_p_i2(x::Number)::Float64
    f = Distributions.G(7.5,1.0)
    return Distributions.pdf(f,x)
end
const n = parse(Int64,ARGS[1])
const m =parse(Int64,ARGS[4])
const f = parse(Float64,ARGS[2])
const l = Int(ceil(n*f))
const c = parse(Int64,ARGS[5])
const it = parse(Int64,ARGS[6])
const rt = parse(Int64,ARGS[7])

function makeSimulation()
    # initializing agents
    suc = [ComplexAgent(suceptible,0,x->1/10,model_p_i1,x->1/100) for i in 1:l]
    inf = [ComplexAgent(infected,0,x->1/10,model_p_i1,x->1/100) for i in l+1:n]
    N = System(n,vcat(suc,inf),watts_strogatz(n,parse(Int64,ARGS[3]),0.5))
    res = basicSimulation(N,parse(Int64,ARGS[4]),advanceParallel!,(i,N)->evolve(i,N,i_tmin=it,r_tmin=rt))
    return N, res
end

main_path = joinpath("..","outputs",Dates.format(Dates.now(),"dd-mm-YYYY_HH-MM"))
mkdir(main_path)
for i in 1:c
    @time N,res = makeSimulation()
    save_i = lpad(i,Int(floor(log10(c)))+1,"0")
    writeAgents(joinpath(main_path,string("agents_",save_i,".csv")),N)
    writeNetworks(joinpath(main_path,string("con_net_",save_i,".graphml")),N)
    writeEvolution(joinpath(main_path,string("simulation_",save_i,".csv")),res)
end
writeMetaParams(joinpath(main_path,"meta_params.csv"),n,m,c)
@btime N,res = makeSimulation()
#=
N2 = System(MutAgent,n)
N3 = MutSystem(Agent,n)
N4 = MutSystem(MutAgent,n)
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
