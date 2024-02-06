# ------ Tasks -------
"""
An abstract type for tasks that a solver can require.

Example tasks
- ask to evaluate objective function at some points
- ask to evaluate an approximation of the objective (multifidelity BO) at some points
- ask to evaluate constraints at some points
"""
abstract type AbstractTask end

# TODO: it might be reasonable to collect box contraints and sense into a problem specification
# and keep tasks only for evaluation of black box objectives / constraints etc.. If the box
# constraints are known before the optimization starts, we don't need problem oracle to handle
# it
struct GetBoxConstraintsTask <: AbstractTask end
struct GetSenseTask <: AbstractTask end

"""
Task to evaluate the objective function at points `xs`.
"""
struct EvalObjectiveTask{S<:Real} <: AbstractTask
    xs::Vector{Vector{S}}
end

# ------ Responses -------
"""
An abstract type for responses to tasks that a solver can require.
"""
abstract type AbstractResponse end

struct GetBoxConstraintsResponse{S<:Real} <: AbstractResponse
    lb::Vector{S}
    ub::Vector{S}
end

struct GetSenseResponse <: AbstractResponse
    sense::Sense
end

"""
Response to task of evaluating the objective function at points `xs`.
"""
struct EvalObjectiveResponse{S<:Real,T<:Real} <: AbstractResponse
    xs::Vector{Vector{S}}
    ys::Vector{T}
end

# ---------- Communication logging ---------

# TODO: create a strategy for logging communication between tasks and responses
# Ideas & requirements:
# - wrap a solver and forward ask & tell but during forwarding log communication, "man-in-the-middle"
# - be able to save current optimization state to file and restore later
# - support verbose levels
# - combine logging with logging of the internal solver

# TODO: maybe it is weird that CommunicationLogger <: AbstractAskTellSolver .. "man-in-the-middle" hack
struct CommunicationLogger{S<:AbstractAskTellSolver} <: AbstractAskTellSolver
    solver::S
end

"""
    ask(c::CommunicationLogger)

Forward ask to wrapped solver and log communication in between.
"""
function ask(c::CommunicationLogger)
    task, tell = ask(c.solver)
    log_communication(task)
    log_then_tell = response -> begin
        log_communication(response)
        tell(response)
    end
    return task, log_then_tell
end

function isdone(c::CommunicationLogger)
    # TODO: maybe log isdone states too?
    isdone(c.solver)
end

function log_communication(_::GetBoxConstraintsTask)
    @info "Task: GetBoxConstraints"
end

function log_communication(_::GetSenseTask)
    @info "Task: GetSense"
end

function log_communication(task::EvalObjectiveTask)
    @info "Task: EvalObjective; xs = $(task.xs)"
end

function log_communication(r::GetBoxConstraintsResponse)
    @info "Response: GetBoxConstraints; lb = $(r.lb), ub=$(r.ub)"
end

function log_communication(r::GetSenseResponse)
    @info "Task: GetSense; $(r.sense)"
end

function log_communication(r::EvalObjectiveResponse)
    @info "Task: EvalObjective; xs = $(r.xs), ys = $(r.ys)"
end
