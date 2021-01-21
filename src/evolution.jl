include("types.jl")

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

function simpleEvolve!(i::Integer,N::Union{System{BasicAgent},MutSystem{BasicAgent}};i_tmin = 10,r_tmin = 10)
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


function neighs(N::AbstractSystem,G,i::Integer,state::Status)
    neig = LightGraphs.neighbors(G,i)
    neig = [k for k in neig if N.agents[k].state==state]
end

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


function evolve!(i::Integer,N::Union{System{BasicAgent},MutSystem{BasicAgent}};i_tmin = 5,r_tmin=10)
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

function simpleFear(N::System{ComplexAgent},i::Integer)
    neigs1 = neighs(N,N.social_net,i,infected)
    neigs2 = neighs(N,N.social_net,i,deceased)
    if length(neigs1) > 5
        return 0
    else
        return p_i(N.agents[i])
    end
        #return (1-2*length(neigs)/LightGraphs.degree(N.social_net,i))*p_i(N.agents[i])
end

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


function advanceParallel!(N::System,evolveFunction::Function)
    newAgents = Array{typeof(N.agents[1]),1}(undef,N.n)
    for i in 1:N.n
        newAgents[i] = evolveFunction(i,N)
    end
    for i in 1:N.n
        N.agents[i] = newAgents[i]
    end
end


function advanceParallel!(N::MutSystem,evolveFunction::Function)
    newAgents = Array{typeof(N.agents[1]),1}(undef,N.n)
    for i in 1:N.n
        newAgents[i] = evolveFunction(i,N)
    end
    N.agents = newAgents
end

function advanceSequential!(N::System{BasicAgent},evolveFunction::Function)
    for i in 1:N.n
        N.agents[i] = evolveFunction(i,N)
    end
end
function advanceSequential!(N::System{MutBasicAgent},evolveFunction::Function)
    for i in 1:N.n
        evolveFunction(i,N)
    end
end
function advanceSequentialRandom!(N::System{BasicAgent},evolveFunction::Function)
    for i in Random.randperm(N.n)
        N.agents[i] = evolveFunction(i,N)
    end
end
function advanceSequentialRandom!(N::System{MutBasicAgent},evolveFunction::Function)
    for i in Random.randperm(N.n)
        evolveFunction(i,N)
    end
end

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


function basicSimulation(N::AbstractSystem,m::Integer,advanceFunc,evolveFunc)
    result = Array{Status,2}(undef,m+1,N.n)
    result[1,:] = [a.state for a in N.agents]
    for i in 1:m
        advanceFunc(N,evolveFunc)
        result[i+1,:] = [a.state for a in N.agents]
    end
    return result
end

function basicSimulation(N::AbstractSystem,m::Integer,advanceFunc)
    result = Array{Status,2}(undef,m+1,N.n)
    result[1,:] = [a.state for a in N.agents]
    for i in 1:m
        advanceFunc(N)
        result[i+1,:] = [a.state for a in N.agents]
    end
    return result
end

function vaccinate(a::AbstractAgent;efficacy::Float64=0.5)
    p = rand()
    if p < efficacy
        return typeof(a)(immune,a)
    else
        return a
    end
end

function vaccinateSystem!(N::AbstractSystem,vaxStatus,order,dailyVac,efficacy)
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


