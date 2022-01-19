using Pkg
using LightGraphs
using GraphPlot
using Colors
using CairoMakie
using StatsBase
using Plots
using JLD2
using Compose

include("lib.jl")

"""
Take a contact network at a certain state and apply t time steps
of a SIS model.

**PARAMS** :
  - net `LightGraph` : *graph representing the contact network*
  - state `Array{Int32,1}` : *disease status of each vertex*
  - beta `Float64` : *infection rate*
  - alpha `Float64` : *curing rate*
  - t `Int32` : *number of time step*

**RETURNS** :
  - state `Array{Int32,1}` : *The new state of the contact network after t time steps.*
  
"""
function SIS(net,state,beta,alpha,t) 
  
  # This array will let us know if we have already checked if the node should
  # cured at this step or not.
  hasCellBeenChecked = [0 for i in 0:nv(net)]

  # Initialize the new state
  outputstate = state
  for i in 1:t
      for j in LightGraphs.edges(net)
          from = j.src
          to = j.dst
          # check if the nodes can infect each other
          if state[from] == 1 && state[to] == 0
              if rand() < beta
                  outputstate[to] = 1
              end
          elseif state[to] == 1 && state[from] == 0
              if rand() < beta
                  outputstate[from] = 1
              end
          end

          # check both cells can cure themselves, if they have not been checked yet
          if state[from] == 1 && hasCellBeenChecked[from] == 0
              if rand() < alpha
                  outputstate[from] = 0
              end
              hasCellBeenChecked[from] = 1
          elseif state[to] == 1 && hasCellBeenChecked[to] == 0
              if rand() < alpha
                  outputstate[to] = 0
              end
              hasCellBeenChecked[to] = 1
          end
      end
  end

  return outputstate
end

"""
Take a contact network, different diseases (defined by 
different parameters alpha and beta), a number of initial
infected people and process nbsimu simulations of SIS over
t time steps. You will provide the prediction of the
percentage of infected at each time t as well as the
spreading rate of each disease.

**PARAMS** :
  - net `LightGraph` : *graph representing the contact network*
  - nbinf `Int32` : *number of infected at the start of each*
        simulation
  - betas `Array{Float64,1}` : *array of infection rate on edges*
  - alphas `Array{Float64,1}` : *array of curing rate on vertices*
  - t `Int32` : *number of time steps*
  - nbsimu `Int32` : *number of simulations*

**RETURNS** :
  - `Array{Float64,2}` : *the prediction of the percentage of 
        infected at each time step and for each disease. The 
        first dimension contains the time steps and the second
        contains the diseases*
  - `Array{Float64,1}` : *effective spreading rate for each 
        disease*

"""
function Simulation_SIS(net,nbinf,betas,alphas,t,nbsimu)
    
  n = length(alphas)
  avg_infected_percentage = zeros(t, n)
  effective_spreading_rate = zeros(n)

  for i in 1:n
    for step in 1:t
      for j in 1:nbsimu
        # Initialize the state
        state = init_State(nv(net), nbinf)

        # Simulate the disease
        state = SIS(net, state, betas[i], alphas[i], step)

        # Compute the percentage of infected
        avg_infected_percentage[step, i] += sum(state) / nv(net)
      end
      avg_infected_percentage[step, i] /= nbsimu
    end
    effective_spreading_rate[i] = betas[i]/alphas[i]
  end

  return avg_infected_percentage , effective_spreading_rate   
end