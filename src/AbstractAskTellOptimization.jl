"""
Defines an interface and helper utilities for solvers providing ask-tell optimization.

Ask-tell means that the solver is sequentially proposing tasks that need to be processed and
once the user has processed a task, the results are returned to the solver for computing the
next task.

An example task is to evaluate the objective function at a batch of points. The user has the
freedom to evaluate the objective in any way, e.g., schedule or run in parallel and once the
results are available resume optimization.

The benefits are more control over the optimization loop, increased transparency when
evaluating expensive objectives and flexible extentions, e.g., to multifidelity optimization.
Possible downsides are slower optimization since evaluations need to wrapped in task objects.
"""
module AbstractAskTellOptimization

export AbstractAskTellSolver, ask, isdone # AbstractAskTellSolver interface
export optimize!

include("problem.jl")
export AbstractBlackBoxProblem
export BoxConstrainedProblem, Min, Max
export process

include("communication.jl")
export AbstractTask
export GetBoxConstraintsTask, GetSenseTask, EvalObjectiveTask

export AbstractResponse
export GetBoxConstraintsResponse, GetSenseResponse, EvalObjectiveResponse

export CommunicationLogger

include("normalizer.jl")
export Normalizer


"""
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
    optimize!(solver::AbstractAskTellSolver, problem::AbstractBlackBoxProblem)

Run optimization loop for applications that don't require to use ask-tell interface.

For instance if the objective function is a julia function that is passed and not
a real world experiment, the user does not need to control the optimization loop.
"""
function optimize!(solver::AbstractAskTellSolver, problem::AbstractBlackBoxProblem)
    while !isdone(solver)
        task, tell = ask(solver)
        tell(process(task, problem))
    end
end

end
