## Lifting Factor Graphs with Some Unknown Factors (LIFAGU)

This repository contains the source code of the LIFAGU algorithm that has been presented in the paper "Lifting Factor Graphs with Some Unknown Factors" by Malte Luttermann, Ralf Möller, and Marcel Gehrke (ECSQARU 2023).

Our implementation uses the [Julia programming language](https://julialang.org).

## Computing Infrastructure and Required Software Packages

All experiments were conducted using Julia version 1.8.1.
Moreover, we use openjdk version 11.0.20 to run the (lifted) inference
algorithms, which are integrated via
`instances/ljt-v1.0-jar-with-dependencies.jar`.

## Instance Generation

Run `julia instance_generator.jl` in the directory `src/` to generate all input
instances for evaluation.
The generated instances are written to the directory `instances/` in binary format.

## Running the Experiments

After generating the instances, the experiments can be started by executing
`julia run_eval.jl` in the directory `src/`.
All results are written to the directory `results/`.
To obtain the plots, first run `julia prepare_plot.jl` in the directory `results/`
to combine the run times into averages and afterwards run the R script `plot.r`,
which creates a `.pdf` file (also in the directory `results/`) containing the
plots.