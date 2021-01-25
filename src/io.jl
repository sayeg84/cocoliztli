
using DelimitedFiles, GraphIO, EzXML

# making directory to write outputs to.
if !(isdir(joinpath("..","outputs")))
    mkdir(joinpath("..","outputs"))
end

"""
writeNetwork(path,G;fmt=GraphIO.GraphML.GraphMLFormat())

Writes network `G` to path `path`
"""
function writeNetwork(path,G;fmt=GraphIO.GraphML.GraphMLFormat())
    LightGraphs.savegraph(path,G,fmt)
end

"""
function writeAgents(path,N::System)

Writes Agent array of `N` to path `path`. It saves the `p_i` with the value for BasicAgent and with the name of the function for Agent and ComplexAgent
"""
function writeAgents(path,N::System)
    open(path,"w+") do io
        write(io,"id,p_i,p_r,p_d\n")
        for i in 1:N.n 
            write(io,"$i,$(N.agents[i].p_i),$(N.agents[i].p_r),$(N.agents[i].p_d)\n")
        end
    end
end
    
"""
writeEvolution(path,res::Array{Status,2})

Writes Agent array of `N` to path `path`. It saves the `p_i` with the value for BasicAgent and with the name of the function for Agent and ComplexAgent
"""
function writeEvolution(path,res::Array{Status,2})
    open(path,"w+") do io
        DelimitedFiles.writedlm(io,[Int8(a) for a in res],',')
    end
end

"""
writeMetaParams(path,n,m,c)

Writes the number of agents `n`, the steps `m` and the independent chains used `c`
"""
function writeMetaParams(path,n,m,c)
    open(path,"w+") do io
        write(io,"n,$n\n")
        write(io,"steps,$m\n")
        write(io,"c,$c\n")
    end
end