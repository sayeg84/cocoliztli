using LightGraphs, Random, DelimitedFiles

@enum Status::Int8 begin
    suceptible = 1
    infected = 2
    recovered = 3
    deceased = 4
    inmune = 5
end

abstract type AbstractAgent end

struct Agent <: AbstractAgent
    state::Status
    t::Int64
    p_i::Float64
    p_r::Float64
    p_d::Float64
    function Agent()
        p = rand()
        return new(rand(instances(Status)),0,rand(),p,rand()*(1-p))
    end
    function Agent(state)
        p = rand()
        return new(state,0,rand(),p,rand()*(1-p))
    end
    function Agent(state,agent)
        return new(state,0,agent.p_i,agent.p_r,agent.p_d)
    end
    function Agent(state,t,p_i,p_r,p_d)
        return new(state,t,p_i,p_r,p_d)
    end
end

mutable struct MutAgent <: AbstractAgent
    state::Status
    t::Int64
    p_i::Float64
    p_r::Float64
    p_d::Float64
    function MutAgent()
        p = rand()
        return new(rand(instances(Status)),0,rand(),p,rand()*(1-p))
    end
    function MutAgent(state)
        p = rand()
        return new(state,0,rand(),p,rand()*(1-p))
    end
    function MutAgent(state,agent)
        return new(state,0,agent.p_i,agent.p_r,agent.p_d)
    end
    function MutAgent(state,t,p_i,p_r,p_d)
        return new(state,t,p_i,p_r,p_d)
    end
end

import Base

function Base.copy(a::AbstractAgent)
    return typeof(a)(a)
end
    
abstract type AbstractNetwork end

struct Network{T<:AbstractAgent} <: AbstractNetwork
    n::Int64
    agents::Array{T,1}
    graph::LightGraphs.SimpleGraphs.AbstractSimpleGraph
end
function Network()
    n = rand(10:100)
    return Network{Agent}(n,[Agent() for i in 1:n],LightGraphs.watts_strogatz(n,Int(floor(n/4)),0.5))
end
function Network(T,n)
    return Network{T}(n,[T() for i in 1:n],LightGraphs.watts_strogatz(n,Int(floor(n/4)),0.5))
end
function Network(T,n,f)
    lim = Int(ceil(n*f))
    suc = [T(suceptible) for i in 1:lim]
    inf = [T(infected) for i in lim+1:n]
    return Network{T}(n,vcat(suc,inf),LightGraphs.watts_strogatz(n,Int(ceil(n/10)),0.5))
end
function Network(T,n,f,l)
    lim = Int(ceil(n*f))
    suc = [T(suceptible) for i in 1:lim]
    inf = [T(infected) for i in lim+1:n]
    return Network{T}(n,vcat(suc,inf),LightGraphs.watts_strogatz(n,l,0.5))
end


function Base.copy(N::Network)
    return Network(N.n,N.agents,N.graph)
end

mutable struct MutNetwork{T<:AbstractAgent} <: AbstractNetwork
    n::Int64
    agents::Array{T,1}
    graph::LightGraphs.SimpleGraphs.AbstractSimpleGraph
end

function MutNetwork()
    n = rand(10:100)
    return MutNetwork{Agent}(n,[Agent() for i in 1:n],LightGraphs.watts_strogatz(n,Int(floor(n/4)),0.5))
end
function MutNetwork(T,n)
    return MutNetwork{T}(n,[T() for i in 1:n],LightGraphs.watts_strogatz(n,Int(floor(n/4)),0.5))
end
function Base.copy(N::MutNetwork)
    return MutNetwork(N.n,N.agents,N.graph)
end


function simpleEvolve(i::Integer,N::AbstractNetwork;i_tmin = 5,r_tmin = 10)
    p = rand()
    a = N.agents[i]
    T = typeof(a)
    if a.state == suceptible
        if p < a.p_i
            return T(infected,a)
        end
    elseif a.state == infected && a.t >= i_tmin
        if p < a.p_r
            return T(recovered,a)
        elseif p < a.p_r + a.p_d
            return T(deceased,a)
        end
    elseif a.state == recovered && a.t >= r_tmin
        return T(suceptible,a)
    end
    return T(a.state,a.t+1,a.p_i,a.p_r,a.p_d)
end

function simpleEvolve!(i::Integer,N::Union{Network{Agent},MutNetwork{Agent}};i_tmin = 10,r_tmin = 10)
    p = rand()
    a = N.agents[i]
    T = typeof(a)
    if a.state == suceptible && p < a.p_i
        N.agents[i] = T(infected,a)
    elseif a.state == infected && a.t >= i_tmin
        if p < a.p_r
            N.agents[i] =  T(recovered,a)
        elseif p < a.p_r + a.p_d
            N.agents[i] =  T(deceased,a)
        else
            N.agents[i] =  T(infected,a.t + 1,a.p_i,a.p_r,a.p_d)
        end
    elseif a.state == recovered && a.t >= r_tmin
        N.agents[i] = T(suceptible,a)
    else 
        N.agents[i] = T(a.state,a.t+1,a.p_i,a.p_r,a.p_d)
    end
end

function simpleEvolve!(i::Integer,N::Union{Network{MutAgent},MutNetwork{MutAgent}};i_tmin = 5,r_tmin = 10)
    p = rand()
    a = N.agents[i]
    a.t += 1
    if a.state == suceptible && p < a.p_i
        a.state = infected
        a.t = 0
    elseif a.state == infected && a.t >= i_tmin
        if p < a.p_r
            a.state = recovered
            a.t = 0
        elseif p < a.p_r + a.p_d
            a.state = deceased
            a.t = 0
        end
    elseif a.state == recovered && a.t >= r_tmin
        a.state = suceptible
    end
end

function evolve(i::Integer,N::AbstractNetwork;i_tmin = 5,r_tmin=10)
    a = N.agents[i]
    T = typeof(a)
    if a.state == suceptible
        for j in LightGraphs.neighbors(N.graph,i)
            if N.agents[j].state == infected
                if rand() < a.p_i*N.agents[j].p_i
                    return T(infected,a)
                end
            end
        end
        return T(suceptible,a.t+1,a.p_i,a.p_r,a.p_d)    
    elseif a.state == infected && a.t >= i_tmin
        p = rand()
        if p < a.p_r
            return T(recovered,a)
        elseif p < a.p_r + a.p_d
            return T(deceased,a)
        else
            return T(infected,a.t+1,a.p_i,a.p_r,a.p_d)
        end
    elseif a.state == recovered && a.t >= r_tmin
        return T(suceptible,a)
    end
    return T(a.state,a.t+1,a.p_i,a.p_r,a.p_d)
end


function evolve!(i::Integer,N::Union{Network{Agent},MutNetwork{Agent}};i_tmin = 5,r_tmin=10)
    a = N.agents[i]
    if a.state == infected
        for j in LightGraphs.neighbors(N.graph,i)
            if rand() < a.p_i*N.agents[j].p_i && N.agents[j].state == suceptible
                N.agents[j] = Agent(infected,a)
            end
        end
        p = rand()
        if a.t >= i_tmin
            if p < a.p_r
                N.agents[i] = Agent(recovered,a)
            elseif p < a.p_r + a.p_d
                N.agents[i] = Agent(deceased,a)
            else
                N.agents[i] = Agent(infected,a.t+1,a.p_i,a.p_r,a.p_d)
            end
        end
    elseif a.state == recovered && a.t >= r_tmin
        N.agents[i] = Agent(suceptible,a)
    else
        N.agents[i] = Agent(a.state,a.t+1,a.p_i,a.p_r,a.p_d)
    end
end

function evolve!(i::Integer,N::Union{Network{MutAgent},MutNetwork{MutAgent}};i_tmin = 5,r_tmin=10)
    a = N.agents[i]
    a.t += 1
    if a.state == infected
        for j in LightGraphs.neighbors(N.graph,i)
            if rand() < a.p_i*N.agents[j].p_i && N.agents[j].state == suceptible
                N.agents[j].state = infected
                N.agents[j].t = 0
            end
        end
        p = rand()
        if a.t >= i_tmin
            if p < a.p_r
                a.state = recovered
                a.t = 0
            elseif p < a.p_r + a.p_d
                a.state = deceased
                a.t = 0
            end
        end
    elseif a.state == recovered && a.t >= r_tmin
        a.state = suceptible
    end
end

function advanceParallel!(N::Network,evolveFunction::Function)
    newAgents = Array{typeof(N.agents[1]),1}(undef,N.n)
    for i in 1:N.n
        newAgents[i] = evolveFunction(i,N)
    end
    for i in 1:N.n
        N.agents[i] = newAgents[i]
    end
end
function advanceParallel!(N::MutNetwork,evolveFunction::Function)
    newAgents = Array{typeof(N.agents[1]),1}(undef,N.n)
    for i in 1:N.n
        newAgents[i] = evolveFunction(i,N)
    end
    N.agents = newAgents
end
function advanceSequential!(N::Network{Agent},evolveFunction::Function)
    for i in 1:N.n
        N.agents[i] = evolveFunction(i,N)
    end
end
function advanceSequential!(N::Network{MutAgent},evolveFunction::Function)
    for i in 1:N.n
        evolveFunction(i,N)
    end
end
function advanceSequentialRandom!(N::Network{Agent},evolveFunction::Function)
    for i in Random.randperm(N.n)
        N.agents[i] = evolveFunction(i,N)
    end
end
function advanceSequentialRandom!(N::Network{MutAgent},evolveFunction::Function)
    for i in Random.randperm(N.n)
        evolveFunction(i,N)
    end
end

function basicSimulation(N::AbstractNetwork,m::Integer,advanceFunc,evolveFunc)
    result = Array{Status,2}(undef,m+1,N.n)
    result[1,:] = [a.state for a in N.agents]
    for i in 1:m
        advanceFunc(N,evolveFunc)
        result[i+1,:] = [a.state for a in N.agents]
    end
    return result
end
