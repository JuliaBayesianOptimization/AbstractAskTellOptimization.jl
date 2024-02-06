"""
`AbstractProblemOracle` is generalizing problem oracles that can process tasks of the solver.

A subtype `MyProblem <: AbstractProblemOracle` must implement the following methods:
- `process(task::T, problem::MyProblem)`
for each task type `T` that a solver that should solve the problem is requiring.
"""
abstract type AbstractProblemOracle end

# ------- BoxConstrainedProblem ----------

# idea from https://github.com/jbrea/BayesianOptimization.jl
@enum Sense Min = -1 Max = 1

"""
Definition of a box constrained optimization problem that can be used in `optimize!` function.

See also [`optimize!`](@ref).
"""
struct BoxConstrainedProblem{S<:Real,T<:Real} <: AbstractProblemOracle
    # Objective f
    f::Function
    #
    # TODO: maybe remove sense, lb, ub from problem oracle (and resp. tasks, responses) as they
    #       do not change - not black box functions, pass them as a problem specification
    #       when initializing a solver
    #
    # either -1 or 1, for maximization +1, for min. -1
    sense::Sense
    # box constraints: lowerbounds, upperbounds
    lb::Vector{S}
    ub::Vector{S}
    # --------- TODO: deal with the following fields from previous versions ------------
    # dimension::Int  # can be inferred from lower, upper bound?
    # domain_eltype::Type
    # range_type::Type
    # TODO: max_evaluations and max total duration, maybe put into a DSM instead (next to check of eval budget)
    # it is not an information for problem eval. but instead more of a config for DSM
    # in seconds,
    # max_duration::T
    # TODO: verbose levels, now Bool
    # verbose::Bool
end

function process(_::GetBoxConstraintsTask, problem::BoxConstrainedProblem)
    problem.lb, problem.ub
end

function process(_::GetSenseTask, problem::BoxConstrainedProblem)
    problem.sense
end

# the only place where f is ever evaluated -> transparency for expensive objective fun.
function process(task::EvalObjectiveTask, problem::BoxConstrainedProblem)
    (problem.f).(task.xs)
end
