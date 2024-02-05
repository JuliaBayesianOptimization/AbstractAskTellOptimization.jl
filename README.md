# AbstractAskTellOptimization

[![Build Status](https://github.com/samuelbelko/AbstractAskTellOptimization.jl/actions/workflows/CI.yml/badge.svg?branch=)](https://github.com/samuelbelko/AbstractAskTellOptimization.jl/actions/workflows/CI.yml?query=branch%3A)

*This repo contains experimental code at the moment.*

## A rough idea

This package defines an interface and helper utilities for solvers performing ask-tell optimization.

Ask-tell means that the solver is sequentially proposing tasks that need to be processed and once the user has processed a task, the results are returned to the solver (currently via a callback `tell` - it might be better to avoid callbacks in the future).

An example task is to evaluate the objective function at a batch of points. The user has the freedom to evaluate the objective in any way, e.g., schedule or run in parallel or do a real world experiment and pass results to the solver once they are available. (Maybe create a new task `AsyncTasks` that consists of tasks that can be returned in any order?)

The benefits are increased transparency in communication with a problem oracle and flexible task extensions, e.g., for multifidelity optimization, where some tasks can be real world experiments and other tasks simulations. Transparent communication makes it easy to track & visualize stats of experiments and results of simulations.
Possible downsides are slower optimization since evaluation requests need to be wrapped in task objects and results returned in result objects.

Probably the main reason for using ask-tell is to *unify different types of optimization tasks*, ranging from efficient experiment design to optimizing objectives written in Julia. Maybe for the user, ask-tell is not as crucial since they could in most cases write an objective function that performs what they try to achieve, e.g., an objective that asks for user input when evaluated or has some side effects, e.g., visualizing evaluations.

Ask-tell can be found along typical "`optimize!`" interface in the following optimization libraries:
- [ax.dev (facebook), Service API](https://ax.dev/docs/api.html)
- [nevergrad (facebook)](https://facebookresearch.github.io/nevergrad/optimization.html#ask-and-tell-interface)
- [trieste](https://secondmind-labs.github.io/trieste/2.0.0/notebooks/ask_tell_optimization.html)
- [optuna](https://optuna.readthedocs.io/en/stable/tutorial/20_recipes/009_ask_and_tell.html)
- [scikit-optimize](https://scikit-optimize.github.io/stable/auto_examples/ask-and-tell.html)

#### `AbstractAskTellSolver` interface

`AbstractAskTellSolver` is generalizing solvers performing ask-tell optimization.

All subtypes `MySolver <: AbstractAskTellSolver` must implement the following methods:
- `ask(solver::MySolver)`
- `isdone(solver::MySolver)`

#### `AbstractProblemOracle` interface

`AbstractProblemOracle` is generalizing problem oracles that can process tasks of the solver.

I imagine a problem oracle as a fairly involved piece of code combining input from GUI, running expensive simulations, evaluating constraints, scheduling experiments, evaluating objective function in parallel and possibly solving some optimization subproblems.

A subtype `MyProblem <: AbstractProblemOracle` must implement the following methods:
- `process(task::T, problem::MyProblem)`
for each task type `T` that a solver that should solve the problem is requiring.

## Idea behind using this API

### For developers of a solver

A solver package should implement `AbstractAskTellSolver` interface on an exported struct `MySolver`. `MySolver` can internally use `Normalizer` to convert problem into a maximization over unit cube and also `CommunicationLogger` to log tasks & responses. `MySolver` should reexport `optimize!` and other potentially useful things (e.g. `BoxConstrainedProblem`).

### For users

Create a `MySolver` object `s` by passing some configuration settings. 

Scenario 1: "I want to optimize a function given by some function I can pass"

Create an instance `p` of `BoxConstrainedProblem <: AbstractProblemOracle` and run `optimize!(s,p)`. (In the future there might be other predefined problem oracles available, e.g., for constrained optimization)

Scenario 2: "I want to build a decision support system that is using Bayesian optimization for sample efficient experiment design"

Run commands you like inside of the following loop or create a custom problem oracle `MyProblem <: AbstractProblemOracle` and run `optimize!`.

```Julia
while !isdone(s)
    task, tell = ask(s)
    # process the task in some way
    result = ...  
    # do some stuff e.g. inspect the model of the optimizer, maybe change some 
    # hyperparameters of the solver (e.g. different acquisition function), 
    # include extra not asked for evaluations,
    # save results to a database,
    # save solver state to file and resume later, visualize statistics of 
    # task evaluations, measure resources for evaluating a task,
    # return task results in a different order when processing in parallel
    # TODO: maybe remove callbacks as it can be difficult to save state 
    #       of the solver to a disk
    tell(result)
end
```

After processing a task, the results need to be wrapped in a respective result object.

### Further notes / ideas

- reuse SciML optimization code, e.g., structs for problem definition
- make use of Julia features such as macros
- create a package for optimization of systems that can only be measured by performing real world experiments, e.g., configuration of a production machine to increase precision
  - `ConfigurationToGo.jl` with a simple GUI (dash.jl?) / REPL app
  - build upon `AbstractAskTellOptimization` interface
  - visualize historical trials, print next tasks, process input from user
  - use GUI to configure main solver settings (e.g. how aggressively acquisition functions are optimized)
  - a multifunctional, easy to use, decision support system for sample efficient parameter search