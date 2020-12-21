include("types.jl")

function simpleEvolve(i::Integer,N::AbstractSystem;i_tmin = 5,r_tmin = 10)
    p = rand()
    a = N.agents[i]
    T = typeof(a)
    if a.state == suceptible
        if p < p_i(a)
            return T(infected,a)
        end
    elseif a.state == infected && a.t >= i_tmin
        if p < p_r(a)
            return T(recovered,a)
        elseif p < p_r(a) + p_d(a)
            return T(deceased,a)
        end
    elseif a.state == recovered && a.t >= r_tmin
        return T(suceptible,a)
    end
    return T(a.state,a.t+1,a.p_i,a.p_r,a.p_d)
end

function simpleEvolve!(i::Integer,N::Union{System{Agent},MutSystem{Agent}};i_tmin = 10,r_tmin = 10)
    p = rand()
    a = N.agents[i]
    T = typeof(a)
    if a.state == suceptible && p < p_i(a)
        N.agents[i] = T(infected,a)
    elseif a.state == infected && a.t >= i_tmin
        if p < p_r(a)
            N.agents[i] =  T(recovered,a)
        elseif p < p_r(a) + p_d(a)
            N.agents[i] =  T(deceased,a)
        else
            N.agents[i] =  T(infected,a.t + 1,p_i(a),p_r(a),p_d(a))
        end
    elseif a.state == recovered && a.t >= r_tmin
        N.agents[i] = T(suceptible,a)
    else 
        N.agents[i] = T(a.state,a.t+1,a.p_i,a.p_r,a.p_d)
    end
end

function simpleEvolve!(i::Integer,N::Union{System{MutAgent},MutSystem{MutAgent}};i_tmin = 5,r_tmin = 10)
    p = rand()
    a = N.agents[i]
    a.t += 1
    if a.state == suceptible && p < p_i(a)
        a.state = infected
        a.t = 0
    elseif a.state == infected && a.t >= i_tmin
        if p < p_r(a)
            a.state = recovered
            a.t = 0
        elseif p < p_r(a) + p_d(a)
            a.state = deceased
            a.t = 0
        end
    elseif a.state == recovered && a.t >= r_tmin
        a.state = suceptible
    end
end

function evolve(i::Integer,N::AbstractSystem;i_tmin = 5,r_tmin=10)
    a = N.agents[i]
    T = typeof(a)
    if a.state == suceptible
        for j in LightGraphs.neighbors(N.contact_net,i)
            if N.agents[j].state == infected
                if rand() < p_i(a)*p_i(N.agents[j])
                    return T(infected,a)
                end
            end
        end
        return T(suceptible,a.t+1,a.p_i,a.p_r,a.p_d)    
    elseif a.state == infected && a.t >= i_tmin
        p = rand()
        if p < p_r(a)
            return T(recovered,a)
        elseif p < p_r(a) + p_d(a)
            return T(deceased,a)
        else
            return T(infected,a.t+1,a.p_i,a.p_r,a.p_d)
        end
    elseif a.state == recovered && a.t >= r_tmin
        return T(suceptible,a)
    end
    return T(a.state,a.t+1,a.p_i,a.p_r,a.p_d)
end


function evolve!(i::Integer,N::Union{System{Agent},MutSystem{Agent}};i_tmin = 5,r_tmin=10)
    a = N.agents[i]
    if a.state == infected
        for j in LightGraphs.neighbors(N.contact_net,i)
            if rand() < p_i(a)*p_i(N.agents[j]) && N.agents[j].state == suceptible
                N.agents[j] = Agent(infected,a)
            end
        end
        p = rand()
        if a.t >= i_tmin
            if p < p_r(a)
                N.agents[i] = Agent(recovered,a)
            elseif p < p_r(a) + p_d(a)
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

function evolve!(i::Integer,N::Union{System{MutAgent},MutSystem{MutAgent}};i_tmin = 5,r_tmin=10)
    a = N.agents[i]
    a.t += 1
    if a.state == infected
        for j in LightGraphs.neighbors(N.contact_net,i)
            if rand() < p_i(a)*p_i(N.agents[j]) && N.agents[j].state == suceptible
                N.agents[j].state = infected
                N.agents[j].t = 0
            end
        end
        p = rand()
        if a.t >= i_tmin
            if p < p_r(a)
                a.state = recovered
                a.t = 0
            elseif p < p_r(a) + p_d(a)
                a.state = deceased
                a.t = 0
            end
        end
    elseif a.state == recovered && a.t >= r_tmin
        a.state = suceptible
    end
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
function advanceSequential!(N::System{Agent},evolveFunction::Function)
    for i in 1:N.n
        N.agents[i] = evolveFunction(i,N)
    end
end
function advanceSequential!(N::System{MutAgent},evolveFunction::Function)
    for i in 1:N.n
        evolveFunction(i,N)
    end
end
function advanceSequentialRandom!(N::System{Agent},evolveFunction::Function)
    for i in Random.randperm(N.n)
        N.agents[i] = evolveFunction(i,N)
    end
end
function advanceSequentialRandom!(N::System{MutAgent},evolveFunction::Function)
    for i in Random.randperm(N.n)
        evolveFunction(i,N)
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