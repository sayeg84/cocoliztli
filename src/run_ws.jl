
print("Importing Libraries ... ")

include("evolution.jl")
include("io.jl")
using Dates, Distributions, ArgParse, BenchmarkTools

println("Done")

print("Initializing parameters ... ")

function model_p_i1(x::Number)::Float64
    f = Distributions.NegativeBinomial(20,0.45)
    return Distributions.pdf(f,x)
end

function model_p_i2(x::Number)::Float64
    f = Distributions.G(7.5,1.0)
    return Distributions.pdf(f,x)
end

function parseArguments()
    s = ArgParse.ArgParseSettings()
    @add_arg_table! s begin
        "--nodes", "-n"
            arg_type = Int
            default = 1000
            help = "Number of agents for the simulation"
        "--steps", "-m"
            arg_type = Int
            default = 500
            help = "Number of time steps"
        "--sucep", "-s"
            arg_type = Float64
            default = 0.99
            help = "Suceptible fraction at the beggining"
        "--links", "-l"
            arg_type = Int
            default = 25
            help = "Number of links for the network"
        "--chains", "-c"
            arg_type = Int
            default = 5
            help = "Number of independent simulations performed"
        "--i_tmin"
            arg_type = Int
            default = 15
            help = "Obligatory infected time"
        "--r_tmin"
            arg_type = Int
            default = 90
            help = "Obligatory recovered time"
    end
    return ArgParse.parse_args(s)
end



main_path = joinpath("..","outputs",Dates.format(Dates.now(),"dd-mm-YYYY_HH-MM"))
mkdir(main_path)
parsed_args = parseArguments()
println("Done")
println("Making simulations ... ")
#=
function makeSimulation()
    # initializing agents
    suc = [ComplexAgent(suceptible,0,x->1/10,model_p_i1,x->1/100) for i in 1:f]
    inf = [ComplexAgent(infected,0,x->1/10,model_p_i1,x->1/100) for i in f+1:parsed_args["nodes"]]
    N = System(parsed_args["nodes"],vcat(suc,inf),watts_strogatz(parsed_args["nodes"],parsed_args["links"],0.5))
    res = basicSimulation(N,parsed_args["steps"],advanceParallel!,(i,N)->evolve(i,N,i_tmin=parsed_args["i_tmin"],r_tmin=parsed_args["r_tmin"]))
    return N, res
end
=#

const n = parsed_args["nodes"]
const m = parsed_args["steps"]
const f = Int(ceil(parsed_args["nodes"]*parsed_args["sucep"]))
const c = parsed_args["chains"]
const l = parsed_args["links"]
const it = parsed_args["i_tmin"]
const rt = parsed_args["r_tmin"]

function makeSimulation()
    # initializing agents
    suc = [ComplexAgent(suceptible,0,x->1/10,model_p_i1,x->1/100) for i in 1:f]
    inf = [ComplexAgent(infected,0,x->1/10,model_p_i1,x->1/100) for i in f+1:n]
    N = System(n,vcat(suc,inf),watts_strogatz(n,l,0.5))
    res = basicSimulation(N,m,advanceParallel!,(i,N)->evolve(i,N,i_tmin=it,r_tmin=rt))
    return N, res
end

function main()
    for i in 1:c
        println("Running $i")
        @time N,res = makeSimulation()
        save_i = lpad(i,Int(floor(log10(parsed_args["chains"])))+1,"0")
        writeAgents(joinpath(main_path,string("agents_",save_i,".csv")),N)
        writeNetworks(joinpath(main_path,string("con_net_",save_i,".graphml")),N)
        writeEvolution(joinpath(main_path,string("simulation_",save_i,".csv")),res)
    end
    println("Done")
    writeMetaParams(joinpath(main_path,"meta_params.csv"),parsed_args["nodes"],parsed_args["steps"],parsed_args["chains"])
end

main()