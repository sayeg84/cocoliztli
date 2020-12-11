
using DelimitedFiles, GraphIO, EzXML

if !(isdir(joinpath("..","outputs")))
    mkdir(joinpath("..","outputs"))
end

function writeNetwork(name,N::AbstractNetwork;fmt=GraphIO.GraphML.GraphMLFormat())
    LightGraphs.savegraph(name,N.graph,fmt)
end

function writeAgents(name,N::AbstractNetwork)
    open(name,"w+") do io
        write(io,"id,p_i,p_r,p_d\n")
        for i in 1:N.n 
            write(io,"$i,$(N.agents[i].p_i),$(N.agents[i].p_r),$(N.agents[i].p_d)\n")
        end
    end
end
    
function writeSimulation(name,res::Array{Status,2})
    open(name,"w+") do io
        DelimitedFiles.writedlm(io,[Int8(a) for a in res],',')
    end
end