"""
**Growth rate**

TODO
"""
function growthrate(parameters, biomass, i; c = [0.0, 0.0])
  # Default -- species-level regulation
  compete_with = biomass[i]
  effective_K = parameters[:K]
  # If regulation is system-wide (all species share K)
  if parameters[:productivity] == :system
    compete_with = biomass[i]
    effective_K = parameters[:K] / parameters[:np]
    G = 1.0 - compete_with / effective_K
  elseif parameters[:productivity] == :competitive # If there is competition
    compete_with = biomass[i]
    for j in eachindex(biomass)
      if (i != j) & (parameters[:is_producer][j])
        compete_with += parameters[:α] * biomass[j]
      end
    end
    effective_K = parameters[:K]
    G = 1.0 - compete_with / effective_K
  elseif parameters[:productivity] == :nutrients
    limit_n1 = c[1] ./ (parameters[:K1][i] .+ c[1])
    limit_n2 = c[2] ./ (parameters[:K2][i] .+ c[2])
    limiting_nutrient = hcat(limit_n1, limit_n2)
    G = minimum(limiting_nutrient, 2)
  else
    G = 1.0 - compete_with / effective_K
  end
  return G
end

"""
**Species growth - internal**

This function is used internally by `dBdt` and `producer_growth`. It takes the vector of biomass
at each time steps, the model parameters (and the vector of nutrients concentrations
if `productivity = :nutrients`), and return the producers' growth rates for this time step
"""
function get_growth(parameters, biomass; c = 0)
    S = size(parameters[:A], 1)
    growth = zeros(eltype(biomass), S)
    G = zeros(eltype(biomass), S)
    for i in eachindex(biomass)
      if parameters[:is_producer][i]
        gr = growthrate(parameters, biomass, i, c = c)[1]
        G[i] = (parameters[:r] * gr * biomass[i])
        if parameters[:productivity] == :nutrients #Nutrient intake
          growth[i] = G[i] - (parameters[:x][i] * biomass[i])
        else
          growth[i] = G[i]
        end
      else
        growth[i] = - parameters[:x][i] * biomass[i]
      end
    end
    return growth, G
end

"""
**Nutrient uptake**

TODO
"""
function nutrientuptake(parameters, biomass, nutrients, G)
  gr_x_bm = sum(G .* biomass)
  dndt = zeros(eltype(nutrients), length(nutrients))
  for i in eachindex(dndt)
    turnover = parameters[:D] * (parameters[:supply][i] - nutrients[i])
    dndt[i] = turnover - parameters[:υ][i] * gr_x_bm
  end
  return dndt
end

"""
**Consumption**

TODO
"""
function consumption(parameters, biomass)

  # Total available biomass
  bm_matrix = zeros(eltype(parameters[:w]), size(parameters[:w]))
  need_rewire = (parameters[:rewire_method] == :ADBM) | (parameters[:rewire_method] == :Gilljam)
  for i in eachindex(bm_matrix)
    @inbounds bm_matrix[i] = parameters[:w][i] * biomass[last(ind2sub(bm_matrix, i))] * parameters[:A][i]
    if need_rewire
      bm_matrix[i] *= parameters[:costMat][i]
    end
  end

  food_available = vec(sum(bm_matrix, 2))
  f_den = zeros(eltype(biomass), length(biomass))
  for i in eachindex(biomass)
    f_den[i] = parameters[:Γh]*(1.0-parameters[:c]*biomass[i])+food_available[i]
  end
  F = bm_matrix ./ f_den

  xyb = zeros(eltype(biomass), length(biomass))
  for i in eachindex(biomass)
    xyb[i] = parameters[:x][i]*parameters[:y][i]*biomass[i]
  end
  transfered = F.*xyb
  consumed = transfered./parameters[:efficiency]
  consumed[isnan.(consumed)] = 0.0

  gain = vec(sum(transfered, 2))
  loss = vec(sum(consumed, 1))
  return gain, loss
end

"""
**Derivatives**

This function is the one wrapped by the various integration routines. Based on a
timepoint `t`, an array of biomasses `biomass`, and a series of simulation
parameters `p`, it will return `dB/dt` for every species.
"""
function dBdt(derivative, biomass, parameters::Dict{Symbol,Any}, t)
  S = size(parameters[:A], 1)

  # producer growth if NP model
  if parameters[:productivity] == :nutrients
    nutrients = biomass[S+1:end] #nutrients concentration
    nutrients[nutrients .< 0] = 0.0
    biomass = biomass[1:S] #species biomasses
  else
    nutrients = [NaN, NaN]
  end

  # Consumption
  gain, loss = consumption(parameters, biomass)

  # Growth
  growth, G = get_growth(parameters, biomass; c = nutrients)

  # Balance
  dbdt = zeros(eltype(biomass), length(biomass))
  for i in eachindex(dbdt)
    dbdt[i] = growth[i] + gain[i] - loss[i]
    if (dbdt[i] + biomass[i]) < eps()
      dbdt[i] = -biomass[i]
    end
  end

  parameters[:productivity] == :nutrients && append!(dbdt, nutrientuptake(parameters, biomass, nutrients, G))
  for i in eachindex(dbdt)
    derivative[i] = dbdt[i]
  end
  return dbdt
end
