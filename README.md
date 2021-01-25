# Cocoliztli model

Simple model for an agent-based modelling of COVID19 pandemic in Mexico.*Cocoliztli* can be interpreted as the Nahuatl word for a contagious disease. 

## Installation

The simulation is build on the [Julia Language](https://julialang.org/). In order to run it, julia must be installed on the system and its executable must be accesible via PATH.

Python 3 is used for creating plots. Jupyter Lab is also used for interactive simulation

### Dependencies

#### Julia

* LightGraphs
* GraphIO
* EzXML
* Distributions

#### Python

* Matplotlib
* Numpy
* Pandas
* Networkx 

## Running

Execute `run_normal.jl` inside of `src` directory to run a simulation without social network. Run `run_social.jl` for a simulation taking into account the social network. Command line arguments can be given to both scripts. For a list of commandline arguments, please execute the scripts with the `--help`.

After running the simulation, search for the `outputs` directory for a folder with name `folder`,corresponding to the date and time of the simulation execution. `folder` containsthe raw data of the simulation: the networks of the system (in GraphML format), the intial agents condition and the evolution coded in integers. Visualization can be made running  `python visualization.py --path folder` where `folder` is the designated folder.


