using LightGraphs, Random, DelimitedFiles

@enum Status::Int8 begin
    suceptible = 1
    infected = 2
    recovered = 3
    deceased = 4
    immune = 5
end

abstract type AbstractAgent end

struct BasicAgent <: AbstractAgent
    state::Status
    t::Int64
    p_i::Float64
    p_r::Float64
    p_d::Float64
    function BasicAgent()
        p = rand()
        return new(rand(instances(Status)),0,rand(),p,rand()*(1-p))
    end
    function BasicAgent(state)
        p = rand()
        return new(state,0,rand(),p,rand()*(1-p))
    end
    function BasicAgent(state,agent)
        return new(state,0,agent.p_i,agent.p_r,agent.p_d)
    end
    function BasicAgent(state,t,p_i,p_r,p_d)
        return new(state,t,p_i,p_r,p_d)
    end
end

struct Agent <: AbstractAgent
    state::Status
    t::Int16
    p_i::Function
    p_r::Function
    p_d::Function
    function Agent()
        p = rand()
        return new(rand(instances(Status)),0,x->rand(),x->p,x->rand()*(1-p))
    end
    function Agent(state)
        p = rand()
        return new(state,0,x->rand(),x->p,x->rand()*(1-p))
    end
    function Agent(state,agent)
        return new(state,0,agent.p_i,agent.p_r,agent.p_d)
    end
    function Agent(state,t,p_i,p_r,p_d)
        return new(state,t,p_i,p_r,p_d)
    end
end

mutable struct MutBasicAgent <: AbstractAgent
    state::Status
    t::Int16
    p_i::Float64
    p_r::Float64
    p_d::Float64
    function MutBasicAgent()
        p = rand()
        return new(rand(instances(Status)),0,rand(),p,rand()*(1-p))
    end
    function MutBasicAgent(state)
        p = rand()
        return new(state,0,rand(),p,rand()*(1-p))
    end
    function MutBasicAgent(state,agent)
        return new(state,0,agent.p_i,agent.p_r,agent.p_d)
    end
    function MutBasicAgent(state,t,p_i,p_r,p_d)
        return new(state,t,p_i,p_r,p_d)
    end
end

mutable struct MutAgent <: AbstractAgent
    state::Status
    t::Int16
    p_i::Float64
    p_r::Float64
    p_d::Float64
    function MutAgent()
        p = rand()
        return new(rand(instances(Status)),0,x->rand(),x->p,x->rand()*(1-p))
    end
    function MutAgent(state)
        p = rand()
        return new(state,0,x->rand(),x->p,x->rand()*(1-p))
    end
    function MutAgent(state,agent)
        return new(state,0,agent.p_i,agent.p_r,agent.p_d)
    end
    function MutAgent(state,t,p_i,p_r,p_d)
        return new(state,t,p_i,p_r,p_d)
    end
end

struct ComplexAgent <: AbstractAgent
    state::Status
    t::Int16
    p_i::Function
    p_r::Function
    p_d::Function
    # number of infected neighbors in last time
    lin::Int16
    # time since number of infected neighbors changed
    nin_t::Int16
    function ComplexAgent()
        p = rand()
        return new(rand(instances(Status)),0,x->rand(),x->p,x->rand()*(1-p),0,0)
    end
    function ComplexAgent(state)
        p = rand()
        return new(state,0,x->rand(),x->p,x->rand()*(1-p),0,0)
    end
    function ComplexAgent(state,agent)
        return new(state,0,agent.p_i,agent.p_r,agent.p_d,agent.lin,agent.nin_t)
    end
    function ComplexAgent(state,agent,lin,nin_t)
        return new(state,0,agent.p_i,agent.p_r,agent.p_d,lin,nin_t)
    end
    function ComplexAgent(state,t,p_i,p_r,p_d)
        return new(state,t,p_i,p_r,p_d,0,0)
    end
    function ComplexAgent(state,t,p_i,p_r,p_d,lin,nin_t)
        return new(state,t,p_i,p_r,p_d,lin,nin_t)
    end
end



function p_i(a::Union{BasicAgent,MutBasicAgent})
    return a.p_i
end

function p_i(a::Union{Agent,MutAgent,ComplexAgent})
    return a.p_i(a.t)
end

function p_r(a::Union{BasicAgent,MutBasicAgent})
    return a.p_r
end

function p_r(a::Union{Agent,MutAgent,ComplexAgent})
    return a.p_r(a.t)
end

function p_d(a::Union{BasicAgent,MutBasicAgent})
    return a.p_d
end

function p_d(a::Union{Agent,MutAgent,ComplexAgent})
    return a.p_d(a.t)
end


import Base

function Base.copy(a::AbstractAgent)
    return typeof(a)(a)
end
    
abstract type AbstractSystem end

struct System{T<:AbstractAgent} <: AbstractSystem
    n::Int64
    agents::Array{T,1}
    contact_net::LightGraphs.SimpleGraphs.AbstractSimpleGraph
    social_net::LightGraphs.SimpleGraphs.AbstractSimpleGraph
end
function System()
    n = rand(10:100)
    return System{BasicAgent}(n,[BasicAgent() for i in 1:n],LightGraphs.watts_strogatz(n,Int(floor(n/4)),0.5),LightGraphs.watts_strogatz(n,Int(floor(n/4)),0.5))
end
function System(T,n)
    return System{T}(n,[T() for i in 1:n],LightGraphs.watts_strogatz(n,Int(floor(n/4)),0.5),LightGraphs.watts_strogatz(n,Int(floor(n/4)),0.5))
end
function System(T,n,f)
    lim = Int(ceil(n*f))
    suc = [T(suceptible) for i in 1:lim]
    inf = [T(infected) for i in lim+1:n]
    return System{T}(n,vcat(suc,inf),LightGraphs.watts_strogatz(n,Int(ceil(n/10)),0.5),LightGraphs.watts_strogatz(n,Int(floor(n/4)),0.5))
end
function System(T,n::Number,f::Number,l::Number)
    lim = Int(ceil(n*f))
    suc = [T(suceptible) for i in 1:lim]
    inf = [T(infected) for i in lim+1:n]
    return System{T}(n,vcat(suc,inf),LightGraphs.watts_strogatz(n,l,0.5),LightGraphs.watts_strogatz(n,Int(floor(n/4)),0.5))
end


function Base.copy(N::System)
    return System(N.n,N.agents,N.contact_net,N.social_net)
end

mutable struct MutSystem{T<:AbstractAgent} <: AbstractSystem
    n::Int64
    agents::Array{T,1}
    contact_net::LightGraphs.SimpleGraphs.AbstractSimpleGraph
end

function MutSystem()
    n = rand(10:100)
    return MutSystem{BasicAgent}(n,[BasicAgent() for i in 1:n],LightGraphs.watts_strogatz(n,Int(floor(n/4)),0.5))
end

function MutSystem(T,n)
    return MutSystem{T}(n,[T() for i in 1:n],LightGraphs.watts_strogatz(n,Int(floor(n/4)),0.5))
end

function Base.copy(N::MutSystem)
    return MutSystem(N.n,N.agents,N.contact_net)
end


