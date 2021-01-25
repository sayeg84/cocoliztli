using LightGraphs, Random, DelimitedFiles
"""
Status::Int8

Enum type to represent the status of the infection of a host. Advantage of using Enum type is the allowance of refering to the status as a string which makes the code much more readable.
"""
@enum Status::Int8 begin
    suceptible = 1
    infected = 2
    recovered = 3
    deceased = 4
    immune = 5
end

"""
abstract type AbstractAgent

Type for representing agents
"""
abstract type AbstractAgent end


"""
BasicAgent

Custom immutable type to represent a simple agent. It contains the following types

| Field | Type | Description |
| :-:   | :-: | :-:         |
| `state` | `Status` | Description of current status of the Agent |
| `t` | `Int64` | Time the agent has spent in its current status |
| `p_i` | `Float64` | If `state` == suceptible, `p_i` is the probability of being infected if in contact with an infected neighbor. Else If `state` == infected, it is the probability of passing the disease to a suceptible neighbor |
| `p_d` | `Float64` | If `state` == infected, `p_d` is the probability of dying |
| `p_r` | `Float64` | If `state` == infected, `p_r` is the probability of becoming `recovered` in each step of time |
"""
struct BasicAgent <: AbstractAgent
    state::Status
    t::Int16
    p_i::Float64
    p_r::Float64
    p_d::Float64

    """
    BasicAgent()

    Initialization of BasicAgent using with random state and random uniform 0-1 random numbers for `p_i`, `p_d` and `p_r`. `p_d` and `p_r` are carefully choosen so that their sum doesn't exceed 1. `t` is initialized in 0.
    """
    function BasicAgent()
        p = rand()
        return new(rand(instances(Status)),0,rand(),p,rand()*(1-p))
    end

    """
    BasicAgent(state)

    Initialization of BasicAgent with state `state` and random uniform 0-1 random numbers for. `p_i`, `p_d` and `p_r`. `p_d` and `p_r` are carefully choosen so that their sum doesn't exceed 1. `t` is initialized in 0.
    """
    function BasicAgent(state)
        p = rand()
        return new(state,0,rand(),p,rand()*(1-p))
    end

    """
    function BasicAgent(state,agent)

    Initialization of BasicAgent with state `state`, `t`=0 and all other parameters inherited of BasicAgent `agent`. 
    """
    function BasicAgent(state,agent)
        return new(state,0,agent.p_i,agent.p_r,agent.p_d)
    end

    """
    BasicAgent(state,t,p_i,p_r,p_d)

    Default initialization of BasicAgent specifying all the fields.
    """
    function BasicAgent(state,t,p_i,p_r,p_d)
        return new(state,t,p_i,p_r,p_d)
    end
end

"""
MutBasicAgent

Custom type to represent a basic agent. The mutable versión of `BasicAgent`. It was originally implemented to compare performance of immutable vs mutable agents. 

Immutable performance is much better so this is legacy code only kept for future proofing. Initialization methods are the same of BasicAgent. Please refer to its documentation for more info.
"""
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

"""
Agent

Custom immutable type to represent an agent. It cointains the same fields than `BasicAgent`, with the diference that `p_i`,`p_d` and `p_r` are functions (normally of only one variable, `t`) instead of constant floats. Initialization methods are the same of BasicAgent but using constant functions of one variable instead of Floats for the probabilities. Please refer to its documentation for more info.
"""
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


"""
MutAgent

Mutable version of Agent. It was built for performance comparison and now is no longer used. 
"""
mutable struct MutAgent <: AbstractAgent
    state::Status
    t::Int16
    p_i::Function
    p_r::Function
    p_d::Function
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

"""
ComplexAgent

Extension of Agent class. It contains the same fields and adds two new ones:

* `lin::Int16` is the current number of infected neighbors.
* `nin_t::Int16` is the time since the number of infected neighbors has changed. 
"""
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
    """
    ComplexAgent()

    Initialization of ComplexAgent using with random state and random uniform 0-1 random numbers for `p_i`, `p_d` and `p_r`. `p_d` and `p_r` are carefully choosen so that their sum doesn't exceed 1. `t`, `lin` and `nin_t` are initialized in 0.
    """
    function ComplexAgent()
        p = rand()
        return new(rand(instances(Status)),0,x->rand(),x->p,x->rand()*(1-p),0,0)
    end

    """
    ComplexAgent(state)

    Initialization of ComplexAgent using with state `state` and random uniform 0-1 random numbers for `p_i`, `p_d` and `p_r`. `p_d` and `p_r` are carefully choosen so that their sum doesn't exceed 1. `t`, `lin` and `nin_t` are initialized in 0.
    """
    function ComplexAgent(state)
        p = rand()
        return new(state,0,x->rand(),x->p,x->rand()*(1-p),0,0)
    end
    
    """
    ComplexAgent(state,agent)

    Initialization of ComplexAgent using with state `state` and other parameters taken from ComplexAgent `agent`. `t`, ` are initialized in 0.
    """
    function ComplexAgent(state,agent)
        return new(state,0,agent.p_i,agent.p_r,agent.p_d,agent.lin,agent.nin_t)
    end

    """
    ComplexAgent(state,agent,lin,nin_t)

    Initialization of ComplexAgent using specifying `state`, `lin` and `nin_t`. Other parameters taken from ComplexAgent `agent`. `t`, ` are initialized in 0.
    """
    function ComplexAgent(state,agent,lin,nin_t)
        return new(state,0,agent.p_i,agent.p_r,agent.p_d,lin,nin_t)
    end

    """
    ComplexAgent(sstate,t,p_i,p_r,p_d)

    Initialization of ComplexAgent using specifying `state`, `t`, `p_i` ,`p_r`  and `p_d` . `lin` and `nin_t` are initialized in 0
    """
    function ComplexAgent(state,t,p_i,p_r,p_d)
        return new(state,t,p_i,p_r,p_d,0,0)
    end

    """
    ComplexAgent(state,t,p_i,p_r,p_d,lin,nin_t)

    Default initialization
    """
    function ComplexAgent(state,t,p_i,p_r,p_d,lin,nin_t)
        return new(state,t,p_i,p_r,p_d,lin,nin_t)
    end
end


import Base

function Base.copy(a::Union{BasicAgent,Agent})
    return typeof(a)(a.state,a.t,a.p_i,a.p_r,a.p_d)
end

function Base.copy(a::ComplexAgent)
    return typeof(a)(a.state,a.t,a.p_i,a.p_r,a.p_d,a.lin,a.nin_t)
end


"""
p_i(a::Union{BasicAgent,MutBasicAgent})

Method to get the constant value of `p_i for `a`.
"""
function p_i(a::Union{BasicAgent,MutBasicAgent})
    return a.p_i
end

"""
p_i(a::Union{BasicAgent,MutBasicAgent})

Method to get the value of `p_i` function for `a` at the value `a.t`
"""
function p_i(a::Union{Agent,MutAgent,ComplexAgent})
    return a.p_i(a.t)
end

"""
p_r(a::Union{BasicAgent,MutBasicAgent})

Method to get the constant value of `p_r for `a`.
"""
function p_r(a::Union{BasicAgent,MutBasicAgent})
    return a.p_r
end


"""
p_r(a::Union{BasicAgent,MutBasicAgent})

Method to get the value of `p_r` function for `a` at the value `a.t`
"""
function p_r(a::Union{Agent,MutAgent,ComplexAgent})
    return a.p_r(a.t)
end

"""
p_d(a::Union{BasicAgent,MutBasicAgent})

Method to get the constant value of `p_d for `a`.
"""
function p_d(a::Union{BasicAgent,MutBasicAgent})
    return a.p_d
end

"""
p_d(a::Union{BasicAgent,MutBasicAgent})

Method to get the value of `p_d` function for `a` at the value `a.t`
"""
function p_d(a::Union{Agent,MutAgent,ComplexAgent})
    return a.p_d(a.t)
end


"""
AbstractSystem

Type for encompasing all of the systems
"""
abstract type AbstractSystem end


"""
System{T<:AbstractAgent} <: AbstractSystem

Parametric type for representing a simulation system. Although it is not mutable, it has mutable fields. 

| Field | Type | Description |
| :-:   | :-: | :-:         |
| `n` | `Int64` | Number of agents |
| `agents` | `Array{T,1}` | Array of length `n` containing all agents of type `T` |
| `contact_net` | `LightGraphs.SimpleGraphs.AbstractSimpleGraph` | Simple graph with `n` nodes. It represents the physical contact network between agents. The default order of its nodes is the same order of the agents |
| `social_net` | `LightGraphs.SimpleGraphs.AbstractSimpleGraph` | Simple graph with `n` nodes. It represents the social network between neighbors. The default order of its nodes is the same order of the agents |
"""
struct System{T<:AbstractAgent} <: AbstractSystem
    n::Int64
    agents::Array{T,1}
    contact_net::LightGraphs.SimpleGraphs.AbstractSimpleGraph
    social_net::LightGraphs.SimpleGraphs.AbstractSimpleGraph
end

"""
System()

Initializing system with between 10 and 100 BasicAgents with random states. 
Social network and contact network are watts_strogatz networks with `floor(n/4)` links and 0.5 randomization.
"""
function System()
    n = rand(10:100)
    return System{BasicAgent}(n,[BasicAgent() for i in 1:n],LightGraphs.watts_strogatz(n,Int(floor(n/4)),0.5),LightGraphs.watts_strogatz(n,Int(floor(n/4)),0.5))
end

"""
System(T,n)

Initializing system with `n` agents of type `T` with random states. 
Social network and contact network are watts_strogatz networks with `floor(n/4)` links and 0.5 randomization.
"""
function System(T,n)
    return System{T}(n,[T() for i in 1:n],LightGraphs.watts_strogatz(n,Int(floor(n/4)),0.5),LightGraphs.watts_strogatz(n,Int(floor(n/4)),0.5))
end

"""
System(T,n)

Initializing system with `n` agents of type `T`. A fraction `f` of the agents are initialized in state `suceptible` and the rest are initializes in `infected`
Social network and contact network are watts_strogatz networks with `floor(n/4)` links and 0.5 randomization.
"""
function System(T,n,f)
    lim = Int(ceil(n*f))
    suc = [T(suceptible) for i in 1:lim]
    inf = [T(infected) for i in lim+1:n]
    return System{T}(n,vcat(suc,inf),LightGraphs.watts_strogatz(n,Int(ceil(n/10)),0.5),LightGraphs.watts_strogatz(n,Int(floor(n/4)),0.5))
end

"""
System(T,n)

Initializing system with `n` agents of type `T`. A fraction `f` of the agents are initialized in state `suceptible` and the rest are initializes in `infected`
Social network and contact network are watts_strogatz networks with `l` links and 0.5 randomization.
"""
function System(T,n::Number,f::Number,l::Number)
    lim = Int(ceil(n*f))
    suc = [T(suceptible) for i in 1:lim]
    inf = [T(infected) for i in lim+1:n]
    return System{T}(n,vcat(suc,inf),LightGraphs.watts_strogatz(n,l,0.5),LightGraphs.watts_strogatz(n,l,0.5))
end


function Base.copy(N::System)
    return System(N.n,N.agents,N.contact_net,N.social_net)
end


"""
MutSystem{T<:AbstractAgent} <: AbstractSystem

Mutable version of System. It was built for comparison reasons and it is no longer used.

Most initializers follow the same rules as the ones of System. Refer to its documentation for more information.
"""
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


