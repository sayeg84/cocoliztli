include("types.jl")

"""
simpleEvolve(i::Integer,N::AbstractSystem;i_tmin = 5,r_tmin = 10)

Simple evolution rule for a system. It takes agent `a=N.agents[i]` and returns a new agent object based on the following transition: 

* If the agent is suceptible, it becomes infected with probability `p_i(a)`, 

* If the agent is infected, it becomes deceased with probability `p_d(a)`.

* If it is infected, it becomes recovered with probability `p_r(a)` only if the time in infected is larger than `i_tmin`
    
* If it is recovered, it goes to suceptible when time as recovered exceeds `r_tmin`
    
For use with `advanceParallel`.
"""
function simpleEvolve(i::Integer,N::AbstractSystem;i_tmin = 5,r_tmin = 10)
    p = rand()
    a = N.agents[i]
    T = typeof(a)
    if a.state == suceptible
        if p < p_i(a)
            return T(infected,a)
        end
    elseif a.state == infected 
        if p < p_d(a)
            return T(deceased,a)
        elseif p < p_d(a) + p_r(a) && a.t >= i_tmin
            return T(recovered,a)
        end
    elseif a.state == recovered && a.t >= r_tmin
        return T(suceptible,a)
    end
    return T(a.state,a.t+1,a.p_i,a.p_r,a.p_d)
end

"""
simpleEvolve!(i::Integer,N::Union{System{BasicAgent},System{Agent},System{ComplexAgent}};i_tmin = 10,r_tmin = 10)

Equivalent of `simpleEvolve` but instead of returning a new agent it changes the existing agent in the system. Useful for use with `advanceSequential` and `advanceSequentialRandom`.
"""
function simpleEvolve!(i::Integer,N::Union{System{BasicAgent},System{Agent},System{ComplexAgent}};i_tmin = 10,r_tmin = 10)
    p = rand()
    a = N.agents[i]
    T = typeof(a)
    if a.state == suceptible && p < p_i(a)
        N.agents[i] = T(infected,a)
    elseif a.state == infected 
        if p < p_d(a)
            N.agents[i] =  T(deceased,a)
        elseif p < p_r(a) + p_d(a) && a.t >= i_tmin
            N.agents[i] =  T(recovered,a)
        else
            N.agents[i] =  T(infected,a.t + 1,p_i(a),p_r(a),p_d(a))
        end
    elseif a.state == recovered && a.t >= r_tmin
        N.agents[i] = T(suceptible,a)
    else 
        N.agents[i] = T(a.state,a.t+1,a.p_i,a.p_r,a.p_d)
    end
end

"""
simpleEvolve!(i::Integer,N::Union{System{MutBasicAgent},MutSystem{MutBasicAgent}};i_tmin = 5,r_tmin = 10)

Equivalent of `simpleEvolve` but instead of returning a new agent it changes the existing Mutable agent in the system. Useful for use with `advanceSequential` and `advanceSequentialRandom`.

No longer used
"""
function simpleEvolve!(i::Integer,N::Union{System{MutBasicAgent},MutSystem{MutBasicAgent}};i_tmin = 5,r_tmin = 10)
    p = rand()
    a = N.agents[i]
    a.t += 1
    if a.state == suceptible && p < p_i(a)
        a.state = infected
        a.t = 0
    elseif a.state == infected 
        if p < p_d(a)
            a.state = deceased
            a.t = 0
        elseif p < p_r(a) + p_d(a) && a.t >= i_tmin
            a.state = recovered
            a.t = 0
        end
    elseif a.state == recovered && a.t >= r_tmin
        a.state = suceptible
    end
end

"""
neighs(N::AbstractSystem,G,i::Integer,state::Status)

returns the list of neighbors of node `i` of graph `G` of system `N` that have status `state`.
"""
function neighs(N::AbstractSystem,G,i::Integer,state::Status)
    neig = LightGraphs.neighbors(G,i)
    neig = [k for k in neig if N.agents[k].state==state]
    return neig
end

"""
function evolve(i::Integer,N::AbstractSystem;i_tmin = 5,r_tmin=10)

Evolution rule for a system. It takes agent `a=N.agents[i]` and returns a new agent object based on the following transition: 

* If the agent is suceptible and has a neighbor in the contact network `b` that is infected, the `a` becomes infected with probability `p_i(a)*p_i(b)`, 

* If the agent is infected, it becomes deceased with probability `p_d(a)`.

* If it is infected, it becomes recovered with probability `p_r(a)` only if the time in infected is larger than `i_tmin`
 
* If it is recovered, it goes to suceptible when time as recovered exceeds `r_tmin`


For use with `advanceParallel`.
"""
function evolve(i::Integer,N::AbstractSystem;i_tmin = 5,r_tmin=10)
    a = N.agents[i]
    T = typeof(a)
    if a.state == suceptible
        for j in neighs(N,N.contact_net,i,infected)
            if N.agents[j].state == infected
                if rand() < p_i(a)*p_i(N.agents[j])
                    return T(infected,a)
                end
            end
        end  
        return T(suceptible,a.t+1,a.p_i,a.p_r,a.p_d)    
    elseif a.state == infected 
        p = rand()
        if p < p_d(a)
            return T(deceased,a)
        elseif p < p_r(a) + p_d(a) && a.t >= i_tmin
            return T(recovered,a)
        else
            return T(infected,a.t+1,a.p_i,a.p_r,a.p_d)
        end
    elseif a.state == recovered && a.t >= r_tmin
        return T(suceptible,a)
    end
    return T(a.state,a.t+1,a.p_i,a.p_r,a.p_d)
end


"""
function evolve!(i::Integer,N::Union{System{BasicAgent},System{Agent},System{ComplexAgent}};i_tmin = 5,r_tmin=10)

Equivalent of `evolve` but changes the agent object instead of returning a new one. For use with `advanceSequential` and `advanceSequentialRandom`
"""
function evolve!(i::Integer,N::Union{System{BasicAgent},System{Agent},System{ComplexAgent}};i_tmin = 5,r_tmin=10)
    a = N.agents[i]
    if a.state == infected
        for j in neighs(N,N.contact_net,i,suceptible)
            if rand() < p_i(a)*p_i(N.agents[j])
                N.agents[j] = BasicAgent(infected,a)
            end
        end
        p = rand()
        if p < p_d(a)
            N.agents[i] = BasicAgent(deceased,a)
        elseif p < p_r(a) + p_d(a) && a.t >= i_tmin
            N.agents[i] = BasicAgent(recovered,a)
        else
            N.agents[i] = BasicAgent(infected,a.t+1,a.p_i,a.p_r,a.p_d)
        end
    elseif a.state == recovered && a.t >= r_tmin
        N.agents[i] = BasicAgent(suceptible,a)
    else
        N.agents[i] = BasicAgent(a.state,a.t+1,a.p_i,a.p_r,a.p_d)
    end
end


"""
function evolve!(i::Integer,N::Union{System{MutBasicAgent},MutSystem{MutBasicAgent}};i_tmin = 5,r_tmin=10)

Equivalent of `evolve!` but for mutable agents.

No longer used
"""
function evolve!(i::Integer,N::Union{System{MutBasicAgent},MutSystem{MutBasicAgent}};i_tmin = 5,r_tmin=10)
    a = N.agents[i]
    a.t += 1
    if a.state == infected
        for j in neighs(N,N.contact_net,i,suceptible)
            if rand() < p_i(a)*p_i(N.agents[j]) 
                N.agents[j].state = infected
                N.agents[j].t = 0
            end
        end
        p = rand()
        if p < p_r(a)
            a.state = recovered
            a.t = 0
        elseif p < p_r(a) + p_d(a) && a.t >= i_tmin
            a.state = deceased
            a.t = 0
        end
    elseif a.state == recovered && a.t >= r_tmin
        a.state = suceptible
    end
end


"""
simpleFear(N::System{ComplexAgent},i::Integer)

Fear function. If the agent has more than five infected neighbors, it returns 0. In other case, it returns its normal probability of infecting.
"""
function simpleFear(N::System{ComplexAgent},i::Integer)
    neigs1 = neighs(N,N.social_net,i,infected)
    if length(neigs1) > 5
        return 0
    else
        return p_i(N.agents[i])
    end
end

"""
fearEvolve(i::Integer,N::System{ComplexAgent};i_tmin = 5,r_tmin=10,probFunc=simpleFear)

Same evolution rule as `evolve` but for ComplexAgent as it updates the `lin` an `nin_t` variables.

Uses a `probFunc` instead of normal `p_i` for the probabilities of infecting or being infected. 
"""
function fearEvolve(i::Integer,N::System{ComplexAgent};i_tmin = 5,r_tmin=10,probFunc=simpleFear)
    a = N.agents[i]
    T = ComplexAgent
    nin_t = a.nin_t
    neig = neighs(N,N.social_net,i,infected)
    lin = length(neig)
    if lin > a.lin
        nin_t = 0
    else
        nin_t += 1
    end
    if a.state == suceptible
        for j in neighs(N,N.contact_net,i,infected)
            if N.agents[j].state == infected
                if rand() < probFunc(N,i)*probFunc(N,j)
                    return T(infected,a,lin,nin_t)
                end
            end
        end  
        return T(suceptible,a.t+1,a.p_i,a.p_r,a.p_d,lin,nin_t)    
    elseif a.state == infected 
        p = rand()
        if p < p_d(a)
            return T(deceased,a,lin,nin_t)
        elseif p < p_r(a) + p_d(a) && a.t >= i_tmin
            return T(recovered,a,lin,nin_t)
        else
            return T(infected,a.t+1,a.p_i,a.p_r,a.p_d,lin,nin_t)
        end
    elseif a.state == recovered && a.t >= r_tmin
        return T(suceptible,a,lin,nin_t)
    end
    return T(a.state,a.t+1,a.p_i,a.p_r,a.p_d,lin,nin_t)
end


"""
advanceParallel!(N::System,evolveFunction::Function)

Evolves all of the agents at the same time in system `N` using `evolveFunction`.

`evolveFunction must be of the following way ``evolveFunction(i::Integer,N::System)` 

This function changes the the `agents` field of system `N`
"""
function advanceParallel!(N::System,evolveFunction::Function)
    newAgents = Array{typeof(N.agents[1]),1}(undef,N.n)
    for i in 1:N.n
        newAgents[i] = evolveFunction(i,N)
    end
    for i in 1:N.n
        N.agents[i] = newAgents[i]
    end
end

"""
function advanceParallel!(N::MutSystem,evolveFunction::Function)

Evolves all of the agents at the same time in system `N` using `evolveFunction`.

No longer used. Built only for performance comparison.
"""
function advanceParallel!(N::MutSystem,evolveFunction::Function)
    newAgents = Array{typeof(N.agents[1]),1}(undef,N.n)
    for i in 1:N.n
        newAgents[i] = evolveFunction(i,N)
    end
    N.agents = newAgents
end

"""
advanceSequential!(N::System{BasicAgent},evolveFunction::Function)

Evolves each agent in system `N` in the order they are presented in its `agents` field acording to function `evolveFunction`.

`evolveFunction` must be of the form `evolveFunction(i::Integer,N::System)`
"""
function advanceSequential!(N::System{BasicAgent},evolveFunction::Function)
    for i in 1:N.n
        N.agents[i] = evolveFunction(i,N)
    end
end

"""
advanceSequential!(N::System{MutBasicAgent},evolveFunction::Function)

Evolves each agent in system `N` in the order they are presented in its `agents` field acording to function `evolveFunction`.

`evolveFunction` must be of the form `evolveFunction(i::Integer,N::System)`

No longer used, built for performance comparison.
"""
function advanceSequential!(N::System{MutBasicAgent},evolveFunction::Function)
    for i in 1:N.n
        evolveFunction(i,N)
    end
end

"""
advanceSequentialRandom!(N::System{BasicAgent},evolveFunction::Function)

Same as `advanceSequential!` but updates in a random order instead of the normal agent array order.
"""
function advanceSequentialRandom!(N::System{BasicAgent},evolveFunction::Function)
    for i in Random.randperm(N.n)
        N.agents[i] = evolveFunction(i,N)
    end
end

"""
advanceSequentialRandom!(N::System{MutBasicAgent},evolveFunction::Function)

Same as `advanceSequential!` but updates in a random order instead of the normal agent array order.

Built for performance comparison reasons. 
"""
function advanceSequentialRandom!(N::System{MutBasicAgent},evolveFunction::Function)
    for i in Random.randperm(N.n)
        evolveFunction(i,N)
    end
end


"""
specialParallelAdvanceFunc!(N::System;i_tmin = 5,r_tmin=10)

Implements `evolve` rule in parallel for a system.

Built for performance comparison. No longer used
"""
function specialParallelAdvanceFunc!(N::System;i_tmin = 5,r_tmin=10)
    T = typeof(N.agents[1])
    newAgents = Array{T,1}(undef,N.n)
    for i in 1:N.n
        a = N.agents[i]
        if a.state == infected 
            for j in LightGraphs.neighbors(N.contact_net,i)
                if N.agents[j].state == suceptible
                    if rand() < p_i(a)*p_i(N.agents[j])
                        newAgents[j] = T(infected,N.agents[j])
                    end
                end
            end
            p = rand()
            if p < p_d(a)
                newAgents[i] = T(deceased,N.agents[i])
            elseif p < p_r(a) + p_d(a) && a.t >= i_tmin
                newAgents[i] = T(deceased,N.agents[i])
            else
                newAgents[i] = T(infected,a.t+1,a.p_i,a.p_r,a.p_d)
            end
        elseif a.state == recovered && a.t >= r_tmin
            newAgents[i] = T(suceptible,a)
        end
        newAgents[i] = T(a.state,a.t+1,a.p_i,a.p_r,a.p_d)
    end
    for i in 1:N.n
        N.agents[i] = newAgents[i]
    end
end

"""
basicSimulation(N::AbstractSystem,m::Integer,advanceFunc,evolveFunc)

Evolves `N` for `m` steps using `advanceFunc` with `evolveFunc` in each step.

`advanceFunc` must be of the form `advanceFunc(N::System,evolveFunc)`
"""
function basicSimulation(N::AbstractSystem,m::Integer,advanceFunc,evolveFunc)
    result = Array{Status,2}(undef,m+1,N.n)
    result[1,:] = [a.state for a in N.agents]
    for i in 1:m
        advanceFunc(N,evolveFunc)
        result[i+1,:] = [a.state for a in N.agents]
    end
    return result
end

"""
basicSimulation(N::AbstractSystem,m::Integer,advanceFunc,evolveFunc)

Evolves `N` for `m` steps using `advanceFunc` for the whole system in each step.

`advanceFunc` must be of the form `advanceFunc(N::System)`.

Built for performance comparison. No longer used.
"""
function basicSimulation(N::AbstractSystem,m::Integer,advanceFunc)
    result = Array{Status,2}(undef,m+1,N.n)
    result[1,:] = [a.state for a in N.agents]
    for i in 1:m
        advanceFunc(N)
        result[i+1,:] = [a.state for a in N.agents]
    end
    return result
end

"""
vaccinate(a::AbstractAgent;efficacy::Float64=0.5)

Takes agent `a` to immune clase with probability `efficacy`
"""
function vaccinate(a::AbstractAgent;efficacy::Float64=0.5)
    p = rand()
    if p < efficacy
        return typeof(a)(immune,a)
    else
        return a
    end
end


"""
function vaccinateSystem!(N::AbstractSystem,vaxStatus::Array{Bool,1},order::Array{T<:Integer,1},dailyVac::Integer,efficacy::Float64)

Applies `dailyVac` vaccines with efficacy `efficacy` to the agent array of `N` in the order given by array `order`.

It can only vaccinate an agent that has status `suceptible` or `recovered`

# Arguments
- `N::AbstractSystem`: System to vaccinate.
- `vaxStatus::Array{Bool,1}`: Array indicating status of vaccination of agents.
- `order::Array{T<:Integer,1}`: Array of integers detailing the order of vaccination
- `dailyVac::Integer`: Number of maximum vaccinations
- `efficacy::Float64`: efficacy of vaccine.
"""
function vaccinateSystem!(N::AbstractSystem,vaxStatus::Array{Bool,1},order,dailyVac::Integer,efficacy::Float64)
    d = 0
    i = 1
    while d < dailyVac && i <= N.n
        if (N.agents[order[i]].state == suceptible || N.agents[order[i]].state == recovered) && (!vaxStatus[order[i]])
            N.agents[order[i]] = vaccinate(N.agents[order[i]],efficacy=efficacy)
            vaxStatus[order[i]] = true
            d += 1
        end
        i += 1
    end
end

"""
vacSimulation(N::AbstractSystem,m::Integer,advanceFunc,evolveFunc;startDate=250,order=1:N.n,dailyVac=40,efficacy=0.9)

Same as `basicSimulation` but vaccinates population with `dailyVac` vaccines every time step, using order `order`, when the time exceeeds `startDate`
"""
function vacSimulation(N::AbstractSystem,m::Integer,advanceFunc,evolveFunc;startDate=250,order=1:N.n,dailyVac=40,efficacy=0.9)
    result = Array{Status,2}(undef,m+1,N.n)
    result[1,:] = [a.state for a in N.agents]
    vaxStatus = [false for i in 1:N.n]
    for t in 1:m
        if t > startDate
            vaccinateSystem!(N,vaxStatus,order,dailyVac,efficacy)
        end
        advanceFunc(N,evolveFunc)
        result[t+1,:] = [a.state for a in N.agents]
    end
    return result
end


