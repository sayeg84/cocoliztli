
using DelimitedFiles, GraphIO, EzXML

if !(isdir(joinpath("..","outputs")))
    mkdir(joinpath("..","outputs"))
end

function writeNetwork(path,G;fmt=GraphIO.GraphML.GraphMLFormat())
    LightGraphs.savegraph(path,G,fmt)
end

function writeAgents(name,N::System)
    open(name,"w+") do io
        write(io,"id,p_i,p_r,p_d\n")
        for i in 1:N.n 
            write(io,"$i,$(N.agents[i].p_i),$(N.agents[i].p_r),$(N.agents[i].p_d)\n")
        end
    end
end
    
function writeEvolution(name,res::Array{Status,2})
    open(name,"w+") do io
        DelimitedFiles.writedlm(io,[Int8(a) for a in res],',')
    end
end

function writeMetaParams(name,n,m,c)
    open(name,"w+") do io
        write(io,"n,$n\n")
        write(io,"steps,$m\n")
        write(io,"c,$c\n")
    end
end