# TODO
# idea:
#  - normalizer is transforming the problem into maximization over a unit cube
#  - similarly to communication logger, it wraps a solver

struct Normalizer{G <:AbstractAskTellSolver, S <: Real}
    solver::G
    # from black-box problem definition, acquired via initial tasks
    lb::Vector{S}
    ub::Vector{S}
    sense::Sense
end

isdone(n::Normalizer) = isdone(n.solver)

"""
Forwarding ask to wrapped solver but in between unnormalizing `task`, i.e., tasks are converted
back to be wrt original black box problem. And normalizing `tell` callback.

Unit cube domain is mapped to the original domain and the problem sense is turned to the
original problem sense for the `task`. For `tell` the opposite is happening.
"""
function ask(n::Normalizer)
    # TODO: in order to use normalizer, it needs to request lb, ub, sense tasks
    # so it has to be initialized without these fields and at first ask calls require the information
    # after it is initialized, it should forward ask calls to n.solver and norm. / unnorm. in between
    task, tell = ask(n.solver)
    return unnormalize(task, n), normalize(tell, n)
end

function unnormalize(task::EvalObjectiveTask, n)
    EvalObjectiveTask( map(x -> from_unit_cube(x, n.lb, n.ub), task.xs))
end

function normalize(task::EvalObjectiveResponse, n)
    norm_xs =  map(x -> to_unit_cube(x, n.lb, n.ub), task.xs)
    # if maximizing, n.sense is 1 and the problem is not changed
    norm_ys = n.sense .* ys
    EvalObjectiveResponse(norm_xs, norm_ys)
end


"""
    to_unit_cube(x, lb, ub)

Affine linear map from [lb, ub] to [0,1]^dim.
"""
function to_unit_cube(x, lb, ub)
    if length(lb) != length(ub) || !all(lb .<= ub)
        throw(ArgumentError("lowerbounds, upperbounds have different lengths or
                        lowerbounds are not componentwise less or equal to upperbounds"))
    end
    (x .- lb) ./ (ub .- lb)
end

"""
    from_unit_cube(x, lb, ub)

Affine linear map from [0,1]^dim to [lb,ub].
"""
function from_unit_cube(x, lb, ub)
    if length(lb) != length(ub) || !all(lb .<= ub)
        throw(ArgumentError("lowerbounds, upperbounds have different lengths or
                        lowerbounds are not componentwise less or equal to upperbounds"))
    end
    x .* (ub .- lb) .+ lb
end
