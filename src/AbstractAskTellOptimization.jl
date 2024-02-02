module AbstractAskTellOptimization

include("problem.jl")
include("communication.jl")
include("normalizer.jl")

# AbstractAskTellSolver interface
export AbstractAskTellSolver, ask, isdone
export AbstractProblemOracle

export AbstractTask
export GetBoxConstraintsTask, GetSenseTask, EvalObjectiveTask

export AbstractResponse
export GetBoxConstraintsResponse, GetSenseResponse, EvalObjectiveResponse

# useful for applications that don't require control over optimization loop
export optimize!
export BoxConstrainedProblem, Min, Max
export process

# helpers for normalizing problems and communication logging
export CommunicationLogger
export Normalizer

"""
An abstract type generalizing solvers performing ask-tell optimization.

All subtypes `MySolver <: AbstractAskTellSolver` must implement the following methods:
- ask(solver::MySolver)
- isdone(solver::MySolver)
"""
abstract type AbstractAskTellSolver end

"""
    ask(solver::AbstractAskTellSolver)

A method returning a pair consisting of the next `task` and a callback method `tell`.

After processing `task`, use `tell` to return results to the solver.
"""
function ask end

# is it "type piracy on docs" from Base?
"""
    isdone(solver::AbstractAskTellSolver) -> Bool

Return whether optimization loop should stop.
"""
function isdone end

"""
    optimize!(solver::AbstractAskTellSolver, problem::AbstractProblemOracle)

Run optimization for applications that don't require control over the optimization loop.
"""
function optimize!(solver::AbstractAskTellSolver, problem::AbstractProblemOracle)
    while !isdone(solver)
        task, tell = ask(solver)
        tell(process(task, problem))
    end
end

end
