"""
An abstract type generalizing black box optimization problems.

Black box optimization problems are problems where the objective, constraints and related
functions can only be evaluated, e.g., an output of a simulation or of a real world
experiment in a lab.

A subtype `MyProblem <: AbstractBlackBoxProblem` must implement the following methods:
- `process(task::T, problem::MyProblem)`
for each task type `T` that a solver that should solve the problem is requiring.
"""
abstract type AbstractBlackBoxProblem end


# ------- BoxConstrainedProblem ----------

# idea from https://github.com/jbrea/BayesianOptimization.jl
@enum Sense Min = -1 Max = 1

"""
Definition of a box constrained optimization problem that can be used in `optimize!` function.

See also [`optimize!`](@ref).
"""
struct BoxConstrainedProblem{S<:Real,T<:Real} <: AbstractBlackBoxProblem
    # Objective f
    f::Function
    # either -1 or 1, for maximization +1, for min. -1
    sense::Sense
    # box constraints: lowerbounds, upperbounds
    lb::Vector{S}
    ub::Vector{S}
    # --------- TODO: deal with the following historical fields.
    # dimension::Int  # can be inferred from lower, upper bound?
    # domain_eltype::Type
    # range_type::Type
    # TODO: max_evaluations and max total duration, maybe put into a DSM instead (next to check of eval budget)
    # it is not an information for problem eval. but instead more of a config for DSM
    # max_evaluations::Int
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
