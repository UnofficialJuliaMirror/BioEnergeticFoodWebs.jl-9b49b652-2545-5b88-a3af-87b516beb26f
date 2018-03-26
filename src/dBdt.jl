"""
**Growth rate**

TODO
"""
function growthrate(p, b, i; c = [0.0, 0.0])
  # Default -- species-level regulation
  compete_with = b[i]
  effective_K = p[:K]
  # If regulation is system-wide (all species share K)
  if p[:productivity] == :system
    compete_with = b[i]
    effective_K = p[:K] / p[:np]
    G = 1.0 - compete_with / effective_K
  elseif p[:productivity] == :competitive # If there is competition
    compete_with = b[i]
    for j in eachindex(b)
      if (i != j) & (p[:is_producer][j])
        compete_with += p[:α] * b[j]
      end
    end
    effective_K = p[:K]
    G = 1.0 - compete_with / effective_K
  elseif p[:productivity] == :nutrients
    limit_n1 = c[1] ./ (p[:K1][i] .+ c[1])
    limit_n2 = c[2] ./ (p[:K2][i] .+ c[2])
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
function get_growth(b, p; c = 0)
    S = size(p[:A], 1)
    growth = zeros(eltype(b), S)
    G = zeros(eltype(b), S)
    for i in eachindex(b)
      if p[:is_producer][i]
        gr = BioEnergeticFoodWebs.growthrate(p, b, i, c = c)[1]
        G[i] = (p[:r] * gr * b[i])
        if p[:productivity] == :nutrients #Nutrient intake
          growth[i] = G[i] - (p[:x][i] * b[i])
        else
          growth[i] = G[i]
        end
      else
        growth[i] = - p[:x][i] * b[i]
      end
    end
    out = Dict(:growth => growth, :G => G)
    return out
end

"""
**Nutrient uptake**

TODO
"""
function nutrientuptake(nutrients, b, p, prodgrowth)
  nutrient_turnover = p[:D] .* (p[:supply] .- nutrients)
  dndt = nutrient_turnover .- p[:υ] .* sum(prodgrowth .* b)
  return dndt
end

"""
**Consumption**

TODO
"""
function consumption(b, p)
  # Total available biomass
  if p[:rewire_method] ∈ [:ADBM, :Gilljam]
    bm_matrix = p[:w] .* (b'.*p[:A]) .* p[:costMat]
  else
    bm_matrix = p[:w] .* (b'.*p[:A])
  end
  food_available = vec(sum(bm_matrix, 2))

  f_den = p[:Γh]*(1.0+p[:c].*b).+food_available
  F = bm_matrix ./ f_den

  xyb = p[:x].*p[:y].*b
  transfered = F.*xyb
  consumed = transfered./p[:efficiency]
  consumed[isnan.(consumed)] = 0.0

  gain = vec(sum(transfered, 2))
  loss = vec(sum(consumed, 1))
  out = Dict(:gain => gain, :loss => loss)
  return out
end

"""
**Derivatives**

This function is the one wrapped by the various integration routines. Based on a
timepoint `t`, an array of biomasses `biomass`, and a series of simulation
parameters `p`, it will return `dB/dt` for every species.
"""
function dBdt(biomass, p::Dict{Symbol,Any})
  S = size(p[:A], 1)

  # producer growth if NP model
  if p[:productivity] == :nutrients
    nutrients = biomass[S+1:end] #nutrients concentration
    nutrients[nutrients .< 0] = 0
    biomass = biomass[1:S] #species biomasses
  else
    nutrients = [NaN, NaN]
  end

  # Consumption
  cons = consumption(biomass, p)
  gain = cons[:gain]
  loss = cons[:loss]

  # Growth
  g = get_growth(biomass, p, c = nutrients)
  growth = g[:growth]
  G = g[:G]

  # Balance
  dbdt = growth .+ gain .- loss

  # This step makes sure that extinction events will be detected
  for i in eachindex(dbdt)
   if (dbdt[i] + biomass[i] < 100eps()) & (dbdt[i] + biomass[i] > 0.0)
     dbdt[i] = - (biomass[i]+100eps())
   else
     dbdt[i] = dbdt[i]
   end
 end

 # Nutrient turnover
 if p[:productivity] == :nutrients
   dndt = nutrientuptake(nutrients, biomass, p, G)
   dbdt = vcat(dbdt, dndt)
 end

  return dbdt
end
