using Plots, GraphRecipes, LightGraphs, GraphIO, EzXML, DelimitedFiles, StatsBase

include("types.jl")

function makeAnimation(sim,G,savepath,max_frames=100)
    if max_frames >= size(sim)[1]
        rang = 1:size(sim)[1]
    else
        rang = range(1,stop=size(sim)[1],length=max_frames)
        rang = [Int(ceil(x)) for x in rang]
    end
    anim = @animate for i in rang
        p = plot()
        graphplot!(G,nodecolor=Int64.(sim[i,:]),method=:circular)
        title!("t = $(i)")
        p
    end
    gif(anim,joinpath(savepath,"graph.gif"),fps=5)
end

function makeCount(vec,n=4)
    bins = 0.5:n+0.5
    hist = StatsBase.fit(Histogram,vec,bins)
    hist = StatsBase.normalize(hist)
    return hist.weights
end

function plotEvolution(sim)
    labels = ["S","I","R","D"]
    counts = vcat([transpose(makeCount(r)) for r in eachrow(sim)]...)
    for j in 1:size(counts)[2]
        plot!(counts[:,j],label=labels[j],linewidth=2,alpha=0.75)
    end
end

test = abspath(PROGRAM_FILE) == @__FILE__
if test
    path = ARGS[1]
    G = LightGraphs.loadgraph(joinpath(path,"network.graphml"),GraphIO.GraphML.GraphMLFormat())
    sim = DelimitedFiles.readdlm(joinpath(path,"simulation.csv"),',',)
    p = plot()
    plotEvolution(sim)
    ylims!(0,1)
    savefig(joinpath(path,"evolution.png"))
    #makeAnimation(sim,G,joinpath(path,"graph.png"),30)    
end


