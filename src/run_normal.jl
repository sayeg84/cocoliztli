
print("Importing Libraries ... ")

include("evolution.jl")
include("io.jl")
using Dates, Distributions, ArgParse, BenchmarkTools, Random

println("Done")

print("Initializing parameters ... ")



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
            default = 40
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
        "--p_i"
            arg_type = Float64
            default = 0.055
            help = "Probability of infection"
        "--order"
            arg_type = String
            default = "Random"
            help = "Order of vaccination"
    end
    return ArgParse.parse_args(s)
end




const main_path = joinpath("..","outputs",Dates.format(Dates.now(),"dd-mm-YYYY_HH-MM"))
mkdir(main_path)
const parsed_args = parseArguments()
println("Done")
println("Making simulations ... ")

function binomial(x::Number)::Float64
    f = Distributions.NegativeBinomial(20,0.45)
    return Distributions.pdf(f,x)
end

function gamma(x::Number)::Float64
    # parameters obtained via least square fit of experiment
    f = Distributions.Gamma(2.48,5.32)
    if x<=5
        return 0
    else
        return Distributions.pdf(f,x)
    end
end

function constant(x::Number)::Float64
    return parsed_args["p_i"]
end

#=
const n = parsed_args["nodes"]
const m = parsed_args["steps"]
const c = parsed_args["chains"]
const l = parsed_args["links"]
const it = parsed_args["i_tmin"]
const rt = parsed_args["r_tmin"]
=#

const f = Int(ceil(parsed_args["nodes"]*parsed_args["sucep"]))
const G = watts_strogatz(parsed_args["nodes"],parsed_args["links"],0.9)

function makeSimulation()
    # initializing agents
    suc = [Agent(suceptible,0,constant,x->0.7,gamma) for i in 1:f]
    inf = [Agent(infected,0,constant,x->0.7,gamma) for i in f+1:parsed_args["nodes"]]
    N = System(parsed_args["nodes"],Random.shuffle(vcat(suc,inf)),G,G)
    if parsed_args["order"]=="DegUp"
        deg_sequence = degree(N.contact_net)
        order = sort(1:N.n,by = x -> deg_sequence[x],rev=false)
    elseif parsed_args["order"]=="DegDown"
        deg_sequence = degree(N.contact_net)
        order = sort(1:N.n,by = x -> deg_sequence[x],rev=true)
    else
        order = 1:N.n
    end
    res = vacSimulation(N,parsed_args["steps"],advanceParallel!,(i,N)->evolve(i,N,i_tmin=parsed_args["i_tmin"],r_tmin=parsed_args["r_tmin"]),order=order,startDate=25)
    #res = basicSimulation(N,parsed_args["steps"],N->specialParallelAdvanceFunc!(N,i_tmin=parsed_args["i_tmin"],r_tmin=parsed_args["r_tmin"]))
    return N, res
end

function main()
    for i in 1:parsed_args["chains"]
        println("Running $i")
        @time N,res = makeSimulation()
        save_i = lpad(i,Int(floor(log10(parsed_args["chains"])))+1,"0")
        writeAgents(joinpath(main_path,string("agents_",save_i,".csv")),N)
        writeEvolution(joinpath(main_path,string("simulation_",save_i,".csv")),res)
        if i==1
            writeNetwork(joinpath(main_path,"con_net.graphml"),N.contact_net)
        end
    end
    println("Done")
    
    writeMetaParams(joinpath(main_path,"meta_params.csv"),parsed_args["nodes"],parsed_args["steps"],parsed_args["chains"])
end

main()