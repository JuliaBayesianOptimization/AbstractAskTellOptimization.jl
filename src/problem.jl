# idea from https://github.com/jbrea/BayesianOptimization.jl
@enum Sense Min = -1 Max = 1

"""
An abstract type generalizing black box optimization problems.
"""
abstract type AbstractBlackBoxProblem end

"""
Definition of a box constrained optimization problem.
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

function process(_::GetBoxConstraints, problem::BoxConstrainedProblem)
    problem.lb, problem.ub
end

function process(_::GetSense, problem::BoxConstrainedProblem)
    problem.sense
end

# the only place where f is ever evaluated -> transparency for expensive objective fun.
function process(task::EvalObjective, problem::BoxConstrainedProblem)
    (problem.f).(task.xs)
end
