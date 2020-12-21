
using DelimitedFiles, GraphIO, EzXML

if !(isdir(joinpath("..","outputs")))
    mkdir(joinpath("..","outputs"))
end

function writeNetworks(name,S::System;fmt=GraphIO.GraphML.GraphMLFormat())
    LightGraphs.savegraph(name,S.contact_net,fmt)
end

function writeAgents(name,S::System)
    open(name,"w+") do io
        write(io,"id,p_i,p_r,p_d\n")
        for i in 1:S.n 
            write(io,"$i,$(S.agents[i].p_i),$(S.agents[i].p_r),$(S.agents[i].p_d)\n")
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