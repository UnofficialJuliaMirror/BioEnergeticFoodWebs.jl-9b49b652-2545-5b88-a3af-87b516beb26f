#=
Functions for biological rates :
     - metabolic rate
     - growth rate
     - handling time
     - attack rate

When temperature is not included, the functions :
    - no_effect_x for metabolic rate
    - no_effect_r for growth rate
    - no_effect_handlingt for handling time
    - no_effect_attackr for attack rate

return the default values for temperature independent rates.

When temperature is included, they are 4 different functions of temperature dependence :

1) Extended Eppley function:
    - extended_eppley_r for growth rate
    - extended_eppley_x for metabolic rate
2) Exponential Boltzmann-Arrhenius function:
    - exponential_BA_r for growth rate
    - exponential_BA_x for metabolic rate
    - exponential_BA_attackr for attack rate
	- exponential_BA_handlingt for handling time
3) Extended Boltzmann-Arrhenius function (Johnson-Lewin):
    - extended_BA_r for growth rate
    - extended_BA_x for metabolic rate
    - extended_BA_attackr for attack rate
4) Gaussian (inverted Gaussian) function
    - gaussian_r for growth rate
    - gaussian_x for metabolic rate
    - gaussian_attackr for attack rate
	- gaussian_handlingt for handling time

These functions are called in biological_rates.jl, where there are wrapped in one function for each temperature dependence functions:
 	- NoEffectTemperature for the functions with no effect of temperature
	- ExtendedEppley for the extended Eppley functions
	- ExponentialBA for the exponential Boltzmann-Arrhenius functions
	- ExtendedBA for the extended Boltzmann-Arrhenius functions
	- Gaussian for gaussian (inverted Gaussian) functions

Which are then used in model_parameters, as : growthrate = ExtendedEppley(:r), where the rate is specified as a key argument.
This allows to directly specify the function to use for each rate and the set of parameters associated with this function within the parameters.
See the documentation of biological_rates.jl for more details.

The functions of temperature dependence can be called with the default parameters provided :
	- ex: extended_eppley_r()
or with specified parameters :
	- ex : extended_eppley_r(passed_temp_parameters = T_parameters)
where T_parameters are the parameters associated with the extended_eppley_r function.

Internally the function extended_eppley_r (or whichever is chosen) takes 3 arguments:

- species body mass (standardized by the smaller producer species),
- the temperature T in Kelvin,
- the set of parameters p.

(All rates scale with bodymass to an exponent β, and parameters of the functional response also scale with resource bodymass to an exponent β_resource.)

model_parameters still returns a Dict, containing:

- x, the metabolic rate (unchanged)
- r, the intrinsic producer's growth rate, which is now specified for each species
- y, the maximum consumption rate, which is 1/ht, with ht being the handling time
- Γ, the half saturation density, which is 1/(ar * ht), with ar being the attack rate
=#

"""
**No effect of temperature on metabolic rate**

This function is by default called as an argument in `model_parameters` to define a temperature independent metabolic rate.
It returns the default values of metabolic rate when there is no effect of temperature (see Delmas et al 2017).
The function accounts for different metabolic rate according to the type of species (vertebrate, invertebrate, producer)

| Parameter       | Meaning             | Default values | Reference                       |
|:----------------|:--------------------|:---------------|:--------------------------------|
| a_vertebrate    | allometric constant | 0.88           | Brose, Williams & Martinez 2006 |
| a_invertebrate  | allometric constant | 0.3141         | Brose, Williams & Martinez 2006 |
| a_producer      | allometric constant | 0.138          | Brose, Williams & Martinez 2006 |

Internally the function takes 3 arguments:

- species body mass (standardized by the smaller producer species),
- the temperature T,
- the set of parameters p.

"""

function no_effect_x(default_temp_parameters = @NT(a_vertebrate = 0.88, a_invertebrate = 0.3141, a_producer = 0.138); passed_temp_parameters...)
    if length(passed_temp_parameters) != 0
	  tmpargs = passed_temp_parameters[:passed_temp_parameters]
	  temperature_param = merge(default_temp_parameters, tmpargs)
	else
	  temperature_param = default_temp_parameters
	end
    return (bodymass, T, p) ->  (temperature_param.a_vertebrate .* (p[:vertebrates] .& .!p[:is_producer]) + temperature_param.a_invertebrate * (.!p[:vertebrates] .& .!p[:is_producer]) + temperature_param.a_producer .* p[:is_producer]) .* (bodymass.^-0.25)
end

"""
**No effect of temperature on growth rate**

This function is by default called as an argument in `model_parameters` to define a temperature independent growth rate.
It returns a default value for growth rate when there is no effect of temperature (see Delmas et al 2017).

| Parameter       | Meaning             | Default values | Reference                       |
|:----------------|:--------------------|:---------------|:--------------------------------|
| r               | growth rate         | 1              | Brose, Williams & Martinez 2006 |

Internally the function takes 3 arguments (unused in this case):

- species body mass (standardized by the smaller producer species),
- the temperature T,
- the set of parameters p.

"""

function no_effect_r(default_temp_parameters = @NT(r = 1); passed_temp_parameters...)
	if length(passed_temp_parameters) != 0
	  tmpargs = passed_temp_parameters[:passed_temp_parameters]
	  temperature_param = merge(default_temp_parameters, tmpargs)
	else
	  temperature_param = default_temp_parameters
	end
    return (bodymass, T, p) -> repeat([temperature_param.r], size(p[:A], 1))
end

"""
**No effect of temperature on handling time**

This function is by default called as an argument in `model_parameters` to define a temperature independent handling time.
It returns a default value for handling time which is defined by 1/y, y being the maximum consumption rate.
The function accounts for different maximum consumption rate values according to the type of species (vertebrate or invertebrate).

| Parameter       | Meaning                                    | Default values | Reference                       |
|:----------------|:-------------------------------------------|:---------------|:--------------------------------|
| y_vertebrate    | maximum consumption rate for vertebrates   | 4.0            | Brose, Williams & Martinez 2006 |
| y_invertebrate  | maximum consumption rate for invertebrates | 8.0            | Brose, Williams & Martinez 2006 |

Internally the function takes 3 arguments (unused in this case):

- species body mass (standardized by the smaller producer species),
- the temperature T,
- the set of parameters p.

"""

function no_effect_handlingt(default_temp_parameters = @NT(y_vertebrate = 4.0, y_invertebrate = 8.0); passed_temp_parameters...)
	if length(passed_temp_parameters) != 0
	  tmpargs = passed_temp_parameters[:passed_temp_parameters]
	  temperature_param = merge(default_temp_parameters, tmpargs)
	else
	  temperature_param = default_temp_parameters
	end
    return (bodymass, T, p) ->  1 ./ (temperature_param.y_vertebrate .* (p[:vertebrates] .& .!p[:is_producer]) + temperature_param.y_invertebrate * (.!p[:vertebrates] .& .!p[:is_producer]))
end

"""
**No effect of temperature on attack rate**

This function is by default called as an argument in `model_parameters` to define a temperature independent attack rate.
It returns a default value for handling time which is defined by 1/(Γ*h), Γ being the half saturation density.

| Parameter  | Meaning                   | Default values | Reference                       |
|:-----------|:--------------------------|:---------------|:--------------------------------|
| Γ          | half-saturation density   | 0.5            | Brose, Williams & Martinez 2006 |

Internally the function takes 3 arguments (unused in this case):

- species body mass (standardized by the smaller producer species),
- the temperature T,
- the set of parameters p.

"""

function no_effect_attackr(default_temp_parameters = @NT(Γ = 0.5); passed_temp_parameters...)
	if length(passed_temp_parameters) != 0
	  tmpargs = passed_temp_parameters[:passed_temp_parameters]
	  temperature_param = merge(default_temp_parameters, tmpargs)
	else
	  temperature_param = default_temp_parameters
	end
    return (bodymass, T, p) -> 1 ./ (temperature_param.Γ .* p[:ht])
end


"""
TODO
**Option 1 : Extended Eppley function for growth rate**

This function can be called as an argument in `model_parameters` to define an extended Eppley funtion (Eppley 1972, Thomas et al. 2012) for producers growth rate.


| Parameter       | Meaning                                                           | Default values| Reference            |
|:----------------|:------------------------------------------------------------------|:--------------|:---------------------|
| maxrate_0       | Maximum rate at 273.15 degrees Kelvin                             | 0.81          | Eppley 1972          |
| eppley_exponent | Exponential rate of increase                                      | 0.0631        | Eppley 1972          |
| T_opt           | location of the maximum of the quadratic portion of the function  | 298.15        | NA                   |
| range           | thermal breadth                                                   | 35            | NA                   |
| β               | allometric exponent                                               | -0.25         | Gillooly et al. 2002 |

Default values are given as an example for growth rate r.

Example:
growthrate=extended_eppley(@NT(maxrate_0=0.81, eppley_exponent=0.0631,T_opt=298.15, range = 35, β = -0.25))
"""

function extended_eppley_r(default_temp_parameters = @NT(maxrate_0 = 0.81, eppley_exponent = 0.0631, T_opt = 298.15, β = -0.25, range = 35); passed_temp_parameters...)
	if length(passed_temp_parameters) != 0
	  tmpargs = passed_temp_parameters[:passed_temp_parameters]
	  temperature_param = merge(default_temp_parameters, tmpargs)
	else
	  temperature_param = default_temp_parameters
	end

    topt = temperature_param.T_opt - 273.15

    return (bodymass, T, p) -> bodymass.^temperature_param.β .* temperature_param.maxrate_0 .* exp(temperature_param.eppley_exponent .* (T.-273.15)) * (1 .- (((T.-273.15) .- topt) ./ (temperature_param.range./2)).^2)
end

"""
TODO
**Option 1 : Extended Eppley function for metabolic rate**

This function can be called as an argument in `model_parameters` to define an extended Eppley function (Eppley 1972, Thomas et al. 2012) for metabolic rate.

| Parameter                     | Meaning                                                                           | Default values| Reference            |
|:------------------------------|:----------------------------------------------------------------------------------|:--------------|:---------------------|
| maxrate_0_producer            | Maximum rate at 273.15 degrees Kelvin for producers                               | 0.81          | Eppley 1972          |
| maxrate_0_invertebrate        | Maximum rate at 273.15 degrees Kelvin for invertebrates                           | 0.81          | Eppley 1972          |
| maxrate_0_vertebrate          | Maximum rate at 273.15 degrees Kelvin for vertebrates                             | 0.81          | Eppley 1972          |
| eppley_exponent_producer      | Exponential rate of increase for producers                                        | 0.0631        | Eppley 1972          |
| eppley_exponent_invertebrate  | Exponential rate of increase for invertebrates                                    | 0.0631        | Eppley 1972          |
| eppley_exponent_vertebrate    | Exponential rate of increase for vertebrates                                      | 0.0631        | Eppley 1972          |
| T_opt_producer                | Location of the maximum of the quadratic portion of the function for producers    | 298.15        | NA                   |
| T_opt_invertebrate            | Location of the maximum of the quadratic portion of the function for invertebrates| 298.15        | NA                   |
| T_opt_producer_vertebrate     | Location of the maximum of the quadratic portion of the function for vertebrates  | 298.15        | NA                   |
| range_producer                | Thermal breadth for producers                                                     | 35            | NA                   |
| range_invertebrate            | Thermal breadth for invertebrates                                                 | 35            | NA                   |
| range_vertebrate              | Thermal breadth for vertebrates                                                   | 35            | NA                   |
| β_producer                    | Allometric exponent for producers                                                 | -0.25         | Gillooly et al. 2002 |
| β_invertebrate                | Allometric exponent for invertebrates                                             | -0.25         | Gillooly et al. 2002 |
| β_vertebrate                  | Allometric exponent for vertebrates                                               | -0.25         | Gillooly et al. 2002 |

Example:
metabolicrate = extended_eppley_x(@NT(maxrate_0_producer = 0.81, maxrate_0_invertebrate = 0.81, maxrate_0_vertebrate = 0.81,
                                     eppley_exponent_producer = 0.0631, eppley_exponent_invertebrate = 0.0631, eppley_exponent_vertebrate = 0.0631,
                                     T_opt_producer = 298.15, T_opt_invertebrate = 298.15, T_opt_vertebrate = 298.15,
                                     range_producer = 35, range_invertebrate = 35, range_vertebrate = 35,
                                     β_producer = -0.25, β_invertebrate = -0.25, β_vertebrate = -0.25))
"""

function extended_eppley_x(default_temp_parameters = @NT(maxrate_0_producer = 0.81, maxrate_0_invertebrate = 0.81, maxrate_0_vertebrate = 0.81,
                                     eppley_exponent_producer = 0.0631, eppley_exponent_invertebrate = 0.0631, eppley_exponent_vertebrate = 0.0631,
                                     T_opt_producer = 298.15, T_opt_invertebrate = 298.15, T_opt_vertebrate = 298.15,
                                     range_producer = 35, range_invertebrate = 35, range_vertebrate = 35,
                                     β_producer = -0.25, β_invertebrate = -0.25, β_vertebrate = -0.25); passed_temp_parameters...)
	if length(passed_temp_parameters) != 0
	  tmpargs = passed_temp_parameters[:passed_temp_parameters]
	  temperature_param = merge(default_temp_parameters, tmpargs)
	else
	  temperature_param = default_temp_parameters
	end

    return (bodymass, T, p) -> for i in 1:1
                                    maxrate_0_all = temperature_param.maxrate_0_producer .* p[:is_producer] .+ temperature_param.maxrate_0_vertebrate .* p[:vertebrates] .+ temperature_param.maxrate_0_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                    eppley_exponent_all = temperature_param.eppley_exponent_producer .* p[:is_producer] .+ temperature_param.eppley_exponent_vertebrate .* p[:vertebrates] .+ temperature_param.eppley_exponent_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                    T_opt_all = temperature_param.T_opt_producer .* p[:is_producer] .+ temperature_param.T_opt_vertebrate .* p[:vertebrates] .+ temperature_param.T_opt_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                    T_opt_all = T_opt_all .- 273.15
                                    range_all = temperature_param.range_producer .* p[:is_producer] .+ temperature_param.range_vertebrate .* p[:vertebrates] .+ temperature_param.range_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                    β_all = temperature_param.β_producer .* p[:is_producer] .+ temperature_param.β_vertebrate .* p[:vertebrates] .+ temperature_param.β_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])

                                    return bodymass.^β_all .* maxrate_0_all .* exp.(eppley_exponent_all .* (T.-273.15)) .* (1 .- (((T.-273.15) .- T_opt_all) ./ (range_all./2)).^2)
                                end
end

"""
**Option 2 : Exponential Boltzmann-Arrhenius function for growth rate**

This function can be called as an argument in `model_parameters` to define an exponential Boltzmann-Arrhénius function (Gillooly et al. 2001, Brown et al. 2004) for producers growth rate.


| Parameter         | Meaning                               | Default values | Reference                             |
|:------------------|:--------------------------------------|:---------------|:--------------------------------------|
| norm_constant     | scaling coefficient                   | -16.54         | Ehnes et al. 2011, Binzer et al. 2012 |
| activation_energy | activation energy                     | -0.69          | Ehnes et al. 2011, Binzer et al. 2012 |
| T0                | normalization temperature (K)         | 293.15         | Binzer et al. 2012, Binzer et al. 2012|
| β                 | allometric exponent                   | -0.31          | Ehnes et al. 2011                     |
| k                 | Boltzmann norm_constant               | 8.617e-5       |                                       |
| T0K               | 0 degrees in Kelvin                   | 273.15         |                                       |

Default values are given as an example for metabolic rate x.

Example:
growthrate=exponential_BA_r(@NT(norm_constant = -16.54, activation_energy = -0.69, T0 = 293.15, β = -0.31))

"""

function exponential_BA_r(default_temp_parameters = @NT(norm_constant = -16.54, activation_energy = -0.69, T0 = 293.15, β = -0.31); passed_temp_parameters...)
    k = 8.617e-5
    T0K = 273.15
	if length(passed_temp_parameters) != 0
	  tmpargs = passed_temp_parameters[:passed_temp_parameters]
	  temperature_param = merge(default_temp_parameters, tmpargs)
	else
	  temperature_param = default_temp_parameters
	end
    return (bodymass, T, p) -> exp(temperature_param.norm_constant) .* (bodymass .^temperature_param.β) .* exp.(temperature_param.activation_energy .* (temperature_param.T0 .- (T + T0K)) ./ (k * (T + T0K) .* temperature_param.T0))
end

"""
**Option 2 : Exponential Boltzmann-Arrhenius function for metabolic rate**

This function can be called as an argument in `model_parameters` to define an exponential Boltzmann-Arrhénius function (Gillooly et al. 2001, Brown et al. 2004) for metabolic rate.


| Parameter                      | Meaning                                         | Default values | Reference                             |
|:-------------------------------|:------------------------------------------------|:---------------|:--------------------------------------|
| norm_constant_producer         | scaling coefficient for producers               | -16.54         | Ehnes et al. 2011, Binzer et al. 2012 |
| norm_constant_invertebrate     | scaling coefficient for invertebrates           | -16.54         | Ehnes et al. 2011, Binzer et al. 2012 |
| norm_constant_vertebrate       | scaling coefficient for vertebrates             | -16.54         | Ehnes et al. 2011, Binzer et al. 2012 |
| activation_energy_producer     | activation energy for producers                 | -0.69          | Ehnes et al. 2011, Binzer et al. 2012 |
| activation_energy_invertebrate | activation energy for invertebrates             | -0.69          | Ehnes et al. 2011, Binzer et al. 2012 |
| activation_energy_vertebrate   | activation energy for vertebrates               | -0.69          | Ehnes et al. 2011, Binzer et al. 2012 |
| T0_producer                    | normalization temperature (K) for producers     | 293.15         | Binzer et al. 2012, Binzer et al. 2012|
| T0_invertebrate                | normalization temperature (K) for invertebrates | 293.15         | Binzer et al. 2012, Binzer et al. 2012|
| T0_vertebrate                  | normalization temperature (K) for vertebrates   | 293.15         | Binzer et al. 2012, Binzer et al. 2012|
| β_producer                     | allometric exponent for producers               | -0.31          | Ehnes et al. 2011                     |
| β_invertebrate                 | allometric exponent for invertebrates           | -0.31          | Ehnes et al. 2011                     |
| β_vertebrate                   | allometric exponent for vertebrates             | -0.31          | Ehnes et al. 2011                     |

Example:
metabolicrate=exponential_BA_x(@NT(norm_constant_producer = -16.54, norm_constant_invertebrate = -16.54, norm_constant_vertebrate = -16.54,
                                   activation_energy_producer = -0.69, activation_energy_invertebrate = -0.69, activation_energy_vertebrate = -0.69,
                                   T0_producer = 293.15, T0_invertebrate = 293.15, T0_vertebrate = 293.15,
                                   β_producer = -0.31, β_invertebrate = -0.31, β_vertebrate = -0.31))

"""

function exponential_BA_x(default_temp_parameters = @NT(norm_constant_producer = -16.54, norm_constant_invertebrate = -16.54, norm_constant_vertebrate = -16.54,
                                   activation_energy_producer = -0.69, activation_energy_invertebrate = -0.69, activation_energy_vertebrate = -0.69,
                                   T0_producer = 293.15, T0_invertebrate = 293.15, T0_vertebrate = 293.15,
                                   β_producer = -0.31, β_invertebrate = -0.31, β_vertebrate = -0.31); passed_temp_parameters...)
    k=8.617e-5
    T0K = 273.15
	if length(passed_temp_parameters) != 0
	  tmpargs = passed_temp_parameters[:passed_temp_parameters]
	  temperature_param = merge(default_temp_parameters, tmpargs)
	else
	  temperature_param = default_temp_parameters
	end

    return (bodymass, T, p) -> for i in 1:1
                                norm_constant_all = temperature_param.norm_constant_producer .* p[:is_producer] .+ temperature_param.norm_constant_vertebrate .* p[:vertebrates] .+ temperature_param.norm_constant_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                activation_energy_all = temperature_param.activation_energy_producer .* p[:is_producer] .+ temperature_param.activation_energy_vertebrate .* p[:vertebrates] .+ temperature_param.activation_energy_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                T0_all = temperature_param.T0_producer .* p[:is_producer] .+ temperature_param.T0_vertebrate .* p[:vertebrates] .+ temperature_param.T0_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                β_all = temperature_param.β_producer .* p[:is_producer] .+ temperature_param.β_vertebrate .* p[:vertebrates] .+ temperature_param.β_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])

                                return exp.(norm_constant_all) .* (bodymass .^β_all) .* exp.(activation_energy_all .* (T0_all .- (T + T0K)) ./ (k * (T + T0K) .* T0_all))
                            end
end

"""
**Option 2 : Exponential Boltzmann-Arrhenius function for functional response : attack rate and handling time**

This function can be called as an argument in `model_parameters` to define an exponential Boltzmann-Arrhénius function (Gillooly et al. 2001, Brown et al. 2004) for one of:
    - attack rate
    - handling time


| Parameter                      | Meaning                                         | Default values | Reference                             |
|:-------------------------------|:------------------------------------------------|:---------------|:--------------------------------------|
| norm_constant_invertebrate     | scaling coefficient for invertebrate            | -16.54         | Ehnes et al. 2011, Binzer et al. 2012 |
| norm_constant_vertebrate       | scaling coefficient for vertebrate              | -16.54         | Ehnes et al. 2011, Binzer et al. 2012 |
| activation_energy_invertebrate | activation energy for invertebrates             | -0.69          | Ehnes et al. 2011, Binzer et al. 2012 |
| activation_energy_vertebrate   | activation energy for vertebrates               | -0.69          | Ehnes et al. 2011, Binzer et al. 2012 |
| T0_invertebrate                | normalization temperature (K) for invertebrates | 293.15         | Binzer et al. 2012, Binzer et al. 2012|
| T0_vertebrate                  | normalization temperature (K) for vertebrates   | 293.15         | Binzer et al. 2012, Binzer et al. 2012|
| β_producer                     | allometric exponent for invertebrate            | -0.31          | Ehnes et al. 2011                     |
| β_invertebrate                 | allometric exponent for invertebrate            | -0.31          | Ehnes et al. 2011                     |
| β_vertebrate                   | allometric exponent for vertebrates             | -0.31          | Ehnes et al. 2011                     |


Example:
attackrate=exponential_BA_functionalr(@NT(norm_constant_vertebrate = -16.54, norm_constant_invertebrate = -16.54,
                                          activation_energy_vertebrate = -0.69, activation_energy_invertebrate = -0.69,
                                          T0_vertebrate = 293.15, T0_invertebrate = 293.15,
                                          β_producer = -0.31, β_vertebrate = -0.31, β_invertebrate = 0.31))

"""
function exponential_BA_attackr(default_temp_parameters = @NT(norm_constant_vertebrate = -13.1, norm_constant_invertebrate = -13.1,
											  activation_energy_vertebrate = -0.38, activation_energy_invertebrate = -0.38,
											  T0_vertebrate = 293.15, T0_invertebrate = 293.15,
											  β_producer = 0.25, β_vertebrate = -0.8, β_invertebrate = -0.8); passed_temp_parameters...)
    k=8.617e-5
    T0K = 273.15
	if length(passed_temp_parameters) != 0
	  tmpargs = passed_temp_parameters[:passed_temp_parameters]
	  temperature_param = merge(default_temp_parameters, tmpargs)
	else
	  temperature_param = default_temp_parameters
	end

    return (bodymass, T, p) -> for i in 1:1
                                norm_constant_all = temperature_param.norm_constant_vertebrate .* p[:vertebrates] .+ temperature_param.norm_constant_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                activation_energy_all = temperature_param.activation_energy_vertebrate .* p[:vertebrates] .+ temperature_param.activation_energy_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                T0_all = temperature_param.T0_vertebrate .* p[:vertebrates] .+ temperature_param.T0_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                β_consumer = temperature_param.β_vertebrate .* p[:vertebrates] .+ temperature_param.β_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])

                                β_resource = zeros(Float64,(p[:S], p[:S]))
                                for consumer in 1:p[:S]
                                for resource in 1:p[:S]
                                  if p[:A][consumer, resource] == 1
                                    if p[:is_producer][resource]
                                        β_resource[consumer, resource] = temperature_param.β_producer
                                    elseif p[:vertebrates][resource]
                                        β_resource[consumer, resource] = temperature_param.β_vertebrate
                                    else
                                        β_resource[consumer, resource] = temperature_param.β_invertebrate
                                    end
                                 end
                                end
                                end
                                rate = exp.(norm_constant_all) .* (bodymass .^β_consumer) .* (bodymass' .^β_resource) .* exp.(activation_energy_all .* (T0_all .- (T + T0K)) ./ (k * (T + T0K) .* T0_all))
                                rate[isnan.(rate)] = 0
                            return rate
                        end
end

"""
**Option 2 : Exponential Boltzmann-Arrhenius function for functional response : attack rate and handling time**

This function can be called as an argument in `model_parameters` to define an exponential Boltzmann-Arrhénius function (Gillooly et al. 2001, Brown et al. 2004) for one of:
    - attack rate
    - handling time


| Parameter                      | Meaning                                         | Default values | Reference                             |
|:-------------------------------|:------------------------------------------------|:---------------|:--------------------------------------|
| norm_constant_invertebrate     | scaling coefficient for invertebrate            | -16.54         | Ehnes et al. 2011, Binzer et al. 2012 |
| norm_constant_vertebrate       | scaling coefficient for vertebrate              | -16.54         | Ehnes et al. 2011, Binzer et al. 2012 |
| activation_energy_invertebrate | activation energy for invertebrates             | -0.69          | Ehnes et al. 2011, Binzer et al. 2012 |
| activation_energy_vertebrate   | activation energy for vertebrates               | -0.69          | Ehnes et al. 2011, Binzer et al. 2012 |
| T0_invertebrate                | normalization temperature (K) for invertebrates | 293.15         | Binzer et al. 2012, Binzer et al. 2012|
| T0_vertebrate                  | normalization temperature (K) for vertebrates   | 293.15         | Binzer et al. 2012, Binzer et al. 2012|
| β_producer                     | allometric exponent for invertebrate            | -0.31          | Ehnes et al. 2011                     |
| β_invertebrate                 | allometric exponent for invertebrate            | -0.31          | Ehnes et al. 2011                     |
| β_vertebrate                   | allometric exponent for vertebrates             | -0.31          | Ehnes et al. 2011                     |


Example:
attackrate=exponential_BA_functionalr(@NT(norm_constant_vertebrate = -16.54, norm_constant_invertebrate = -16.54,
                                          activation_energy_vertebrate = -0.69, activation_energy_invertebrate = -0.69,
                                          T0_vertebrate = 293.15, T0_invertebrate = 293.15,
                                          β_producer = -0.31, β_vertebrate = -0.31, β_invertebrate = 0.31))

"""
function exponential_BA_handlingt(default_temp_parameters = @NT(norm_constant_vertebrate = 9.66, norm_constant_invertebrate = 9.66,
											  activation_energy_vertebrate = 0.26, activation_energy_invertebrate = 0.26,
											  T0_vertebrate = 293.15, T0_invertebrate = 293.15,
											  β_producer = -0.45, β_vertebrate = 0.47, β_invertebrate = 0.47); passed_temp_parameters...)
    k=8.617e-5
    T0K = 273.15
	if length(passed_temp_parameters) != 0
	  tmpargs = passed_temp_parameters[:passed_temp_parameters]
	  temperature_param = merge(default_temp_parameters, tmpargs)
	else
	  temperature_param = default_temp_parameters
	end

    return (bodymass, T, p) -> for i in 1:1
                                norm_constant_all = temperature_param.norm_constant_vertebrate .* p[:vertebrates] .+ temperature_param.norm_constant_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                activation_energy_all = temperature_param.activation_energy_vertebrate .* p[:vertebrates] .+ temperature_param.activation_energy_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                T0_all = temperature_param.T0_vertebrate .* p[:vertebrates] .+ temperature_param.T0_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                β_consumer = temperature_param.β_vertebrate .* p[:vertebrates] .+ temperature_param.β_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])

                                β_resource = zeros(Float64,(p[:S], p[:S]))
                                for consumer in 1:p[:S]
                                for resource in 1:p[:S]
                                  if p[:A][consumer, resource] == 1
                                    if p[:is_producer][resource]
                                        β_resource[consumer, resource] = temperature_param.β_producer
                                    elseif p[:vertebrates][resource]
                                        β_resource[consumer, resource] = temperature_param.β_vertebrate
                                    else
                                        β_resource[consumer, resource] = temperature_param.β_invertebrate
                                    end
                                 end
                                end
                                end
                                rate = exp.(norm_constant_all) .* (bodymass .^β_consumer) .* (bodymass' .^β_resource) .* exp.(activation_energy_all .* (T0_all .- (T + T0K)) ./ (k * (T + T0K) .* T0_all))
                                rate[isnan.(rate)] = 0
                            return rate
                        end
end


"""
**Option 3 : Extended Boltzmann-Arrhenius function for growth rate**


| Parameter          | Meaning                                               | Default values | Reference            |
|:-------------------|:------------------------------------------------------|:---------------|----------------------|
| norm_constant      | scaling coefficient                                   | 3e8            | NA                   |
| activation_energy  | activation energy                                     | 0.53           | Dell et al 2011      |
| deactivation_energy| deactivation energy                                   | 1.15           | Dell et al 2011      |
| T_opt              | temperature at which trait value is maximal           | 298.15         | NA                   |
| β                  | allometric exponent                                   | -0.25          | Gillooly et al. 2002 |

Example:
growthrate=extended_BA_r(@NT(norm_constant = 3e8, activation_energy = 0.53, deactivation_energy = 1.15, T_opt = 298.15, β = -0.25))


"""

function extended_BA_r(default_temp_parameters = @NT(norm_constant = 3e8, activation_energy = 0.53, deactivation_energy = 1.15, T_opt = 298.15, β = -0.25); passed_temp_parameters...)
     if length(passed_temp_parameters) != 0
	  tmpargs = passed_temp_parameters[:passed_temp_parameters]
	  temperature_param = merge(default_temp_parameters, tmpargs)
	else
	  temperature_param = default_temp_parameters
	end
	k = 8.617e-5 # Boltzmann constant
	Δenergy = temperature_param.deactivation_energy .- temperature_param.activation_energy

    return(bodymass, T, p) -> temperature_param.norm_constant .* bodymass .^(temperature_param.β) .* exp.(.-temperature_param.activation_energy ./ (k * T)) .* (1 ./ (1 + exp.(-1 / (k * T) .* (temperature_param.deactivation_energy .- (temperature_param.deactivation_energy ./ temperature_param.T_opt .+ k .* log(temperature_param.activation_energy ./ Δenergy)).*T))))
end


"""
**Option 3 : Extended Boltzmann-Arrhenius function for metabolic rate**


| Parameter                       | Meaning                                                       | Default values | Reference            |
|:--------------------------------|:--------------------------------------------------------------|:---------------|----------------------|
| norm_constant_producer          | scaling coefficient for invertebrates                         | 3e8            | NA                   |
| norm_constant_invertebrate      | scaling coefficient for invertebrates                         | 3e8            | NA                   |
| norm_constant_invertebrate      | scaling coefficient for vertebrates                           | 3e8            | NA                   |
| activation_energy_producer      | activation energy for invertebrates                           | 0.53           | Dell et al 2011      |
| activation_energy_invertebrate  | activation energy for invertebrates                           | 0.53           | Dell et al 2011      |
| activation_energy_vertebrate    | activation energy for vertebrates                             | 0.53           | Dell et al 2011      |
| deactivation_energy_producer    | deactivation energy for invertebrates                         | 1.15           | Dell et al 2011      |
| deactivation_energy_invertebrate| deactivation energy for invertebrates                         | 1.15           | Dell et al 2011      |
| deactivation_energy_vertebrate  | deactivation energy for vertebrates                           | 1.15           | Dell et al 2011      |
| T_opt_producer                  | temperature at which trait value is maximal for invertebrates | 298.15         | NA                   |
| T_opt_invertebrate              | temperature at which trait value is maximal for invertebrates | 298.15         | NA                   |
| T_opt_vertebrate                | temperature at which trait value is maximal for vertebrates   | 298.15         | NA                   |
| β_producer                      | allometric exponent for producers                             | -0.25          | Gillooly et al. 2002 |
| β_invertebrate                  | allometric exponent for invertebrates                         | -0.25          | Gillooly et al. 2002 |
| β_vertebrate                    | allometric exponent for vertebrates                           | -0.25          | Gillooly et al. 2002 |


Example:
metabolicrate=extended_BA_x(@NT(norm_constant_producer = 3e8, norm_constant_invertebrate = 3e8, norm_constant_vertebrate = 3e8,
                                activation_energy_producer = 0.53, activation_energy_invertebrate = 0.53, activation_energy_vertebrate = 0.53,
                                deactivation_energy_producer = 1.15, deactivation_energy_invertebrate = 1.15, deactivation_energy_vertebrate = 1.15,
                                T_opt_producer = 298.15, T_opt_invertebrate = 298.15, T_opt_vertebrate = 298.15,
                                β_producer = -0.25, β_invertebrate = -0.25, β_vertebrate = -0.25))


"""
function extended_BA_x(default_temp_parameters = @NT(norm_constant_producer = 3e8, norm_constant_invertebrate = 3e8, norm_constant_vertebrate = 3e8,
                                activation_energy_producer = 0.53, activation_energy_invertebrate = 0.53, activation_energy_vertebrate = 0.53,
                                deactivation_energy_producer = 1.15, deactivation_energy_invertebrate = 1.15, deactivation_energy_vertebrate = 1.15,
                                T_opt_producer = 298.15, T_opt_invertebrate = 298.15, T_opt_vertebrate = 298.15,
                                β_producer = -0.25, β_invertebrate = -0.25, β_vertebrate = -0.25); passed_temp_parameters...)
     k = 8.617e-5 # Boltzmann constant
	 if length(passed_temp_parameters) != 0
	  tmpargs = passed_temp_parameters[:passed_temp_parameters]
	  temperature_param = merge(default_temp_parameters, tmpargs)
 	else
	  temperature_param = default_temp_parameters
	end

     return(bodymass, T, p) -> for i in 1:1
                                 norm_constant_all = temperature_param.norm_constant_producer .* p[:is_producer] .+ temperature_param.norm_constant_vertebrate .* p[:vertebrates] .+ temperature_param.norm_constant_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                 activation_energy_all = temperature_param.activation_energy_producer .* p[:is_producer] .+ temperature_param.activation_energy_vertebrate .* p[:vertebrates] .+ temperature_param.activation_energy_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                 deactivation_energy_all = temperature_param.deactivation_energy_producer .* p[:is_producer] .+ temperature_param.deactivation_energy_vertebrate .* p[:vertebrates] .+ temperature_param.deactivation_energy_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                 T_opt_all = temperature_param.T_opt_producer .* p[:is_producer] .+ temperature_param.T_opt_vertebrate .* p[:vertebrates] .+ temperature_param.T_opt_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                 β_all = temperature_param.β_producer .* p[:is_producer] .+ temperature_param.β_vertebrate .* p[:vertebrates] .+ temperature_param.β_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                 Δenergy = deactivation_energy_all .- activation_energy_all

                                 return  norm_constant_all .* bodymass .^(β_all) .* exp.(.-activation_energy_all ./ (k * T)) .* (1 ./ (1 + exp.(-1 / (k * T) .* (deactivation_energy_all .- (deactivation_energy_all ./ T_opt_all .+ k .* log.(activation_energy_all ./ Δenergy)).* T))))

                             end
end

"""
**Option 3 : Extended Boltzmann-Arrhenius function for attack rate**


| Parameter                       | Meaning                                                       | Default values | Reference            |
|:--------------------------------|:--------------------------------------------------------------|:---------------|----------------------|
| norm_constant_invertebrate      | scaling coefficient for invertebrates                         | 3e8            | NA                   |
| norm_constant_invertebrate      | scaling coefficient for vertebrates                           | 3e8            | NA                   |
| activation_energy_invertebrate  | activation energy for invertebrates                           | 0.53           | Dell et al 2011      |
| activation_energy_vertebrate    | activation energy for vertebrates                             | 0.53           | Dell et al 2011      |
| deactivation_energy_invertebrate| deactivation energy for invertebrates                         | 1.15           | Dell et al 2011      |
| deactivation_energy_vertebrate  | deactivation energy for vertebrates                           | 1.15           | Dell et al 2011      |
| T_opt_invertebrate              | temperature at which trait value is maximal for invertebrates | 298.15         | NA                   |
| T_opt_vertebrate                | temperature at which trait value is maximal for vertebrates   | 298.15         | NA                   |
| β_producer                      | allometric exponent for producers                             | -0.25          | Gillooly et al. 2002 |
| β_invertebrate                  | allometric exponent for invertebrates                         | -0.25          | Gillooly et al. 2002 |
| β_vertebrate                    | allometric exponent for vertebrates                           | -0.25          | Gillooly et al. 2002 |

Default values are given as an example for attack rate.

Example:
attackrate=extended_BA_attackr(@NT(norm_constant_invertebrate = 3e8, norm_constant_vertebrate = 3e8,
                                   activation_energy_invertebrate = 0.53, activation_energy_vertebrate = 0.53,
                                   deactivation_energy_invertebrate = 1.15, deactivation_energy_vertebrate = 1.15,
                                   T_opt_invertebrate = 298.15, T_opt_vertebrate = 298.15,
                                   β_producer = -0.25, β_invertebrate = -0.25, β_vertebrate = -0.25))


"""
function extended_BA_attackr(default_temp_parameters = @NT(norm_constant_invertebrate = 3e8, norm_constant_vertebrate = 3e8,
                                   activation_energy_invertebrate = 0.53, activation_energy_vertebrate = 0.53,
                                   deactivation_energy_invertebrate = 1.15, deactivation_energy_vertebrate = 1.15,
                                   T_opt_invertebrate = 298.15, T_opt_vertebrate = 298.15,
                                   β_producer = -0.25, β_invertebrate = -0.25, β_vertebrate = -0.25); passed_temp_parameters...)
     k = 8.617e-5 # Boltzmann constant
	 if length(passed_temp_parameters) != 0
	  tmpargs = passed_temp_parameters[:passed_temp_parameters]
	  temperature_param = merge(default_temp_parameters, tmpargs)
	else
	  temperature_param = default_temp_parameters
	end

     return(bodymass, T, p) -> for i in 1:1
                                # parameters vary if the consumer is a vertebrate/invertebrate
                                norm_constant_all = temperature_param.norm_constant_vertebrate .* p[:vertebrates] .+ temperature_param.norm_constant_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                activation_energy_all = temperature_param.activation_energy_vertebrate .* p[:vertebrates] .+ temperature_param.activation_energy_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                deactivation_energy_all = temperature_param.deactivation_energy_vertebrate .* p[:vertebrates] .+ temperature_param.deactivation_energy_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                T_opt_all = temperature_param.T_opt_vertebrate .* p[:vertebrates] .+ temperature_param.T_opt_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                β_consumer = temperature_param.β_vertebrate .* p[:vertebrates] .+ temperature_param.β_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                Δenergy = deactivation_energy_all .- activation_energy_all
                                # β for resources
                                β_resource = zeros(Float64,(p[:S], p[:S]))
                                for consumer in 1:p[:S]
                                for resource in 1:p[:S]
                                  if p[:A][consumer, resource] == 1
                                    if p[:is_producer][resource]
                                        β_resource[consumer, resource] = temperature_param.β_producer
                                    elseif p[:vertebrates][resource]
                                        β_resource[consumer, resource] = temperature_param.β_vertebrate
                                    else
                                        β_resource[consumer, resource] = temperature_param.β_invertebrate
                                    end
                                 end
                                end
                                end
                                rate = norm_constant_all .* bodymass .^(β_consumer) .* bodymass' .^(β_resource) .* exp.(.-activation_energy_all ./ (k * T)) .* (1 ./ (1 + exp.(-1 / (k * T) .* (deactivation_energy_all .- (deactivation_energy_all ./ T_opt_all .+ k .* log.(activation_energy_all ./ Δenergy)).* T))))
                                rate[isnan.(rate)] = 0
                                return  rate

                             end
end

"""
**Option 4 : Gaussian function for growth rate**

| Parameter    | Meaning                                        | Default values | Reference            |
|:-------------|:-----------------------------------------------|:---------------|:---------------------|
| shape        | hump-shaped (:hump) or U-shaped (:U) curve     | :hump          | Amarasekare 2015     |
| norm_constant| minimal/maximal trait value                    | 0.5            | NA                   |
| range        | performance breath (width of function)         | 20             | Amarasekare 2015     |
| T_opt        | temperature at which trait value is maximal    | 295            | Amarasekare 2015     |
| β            | allometric exponent                            | -0.25          | Gillooly et al 2002  |


Example:
growthrate=gaussian_r(@NT(shape = :hump, norm_constant = 0.5, range = 20, T_opt = 295, β = -0.25))

"""
function gaussian_r(default_temp_parameters = @NT(shape = :hump, norm_constant = 0.5, range = 20, T_opt = 295, β = -0.25); passed_temp_parameters...)
	if length(passed_temp_parameters) != 0
	  tmpargs = passed_temp_parameters[:passed_temp_parameters]
	  temperature_param = merge(default_temp_parameters, tmpargs)
	else
	  temperature_param = default_temp_parameters
	end
    return(bodymass, T, p) -> bodymass.^temperature_param.β .* temperature_param.norm_constant .* exp(.-(T .- temperature_param.T_opt).^2 ./ (2 .*temperature_param.range.^2))
end

"""
**Option 4 : Gaussian function for metabolic rate**

| Parameter                  | Meaning                                                       | Default values | Reference            |
|:---------------------------|:--------------------------------------------------------------|:---------------|:---------------------|
| norm_constant_producer     | minimal/maximal trait value for producers                     | 0.5            | NA                   |
| norm_constant_invertebrate | minimal/maximal trait value for invertebrates                 | 0.5            | NA                   |
| norm_constant_vertebrate   | minimal/maximal trait value for vertebrates                   | 0.5            | NA                   |
| T_opt_producer             | temperature at which trait value is maximal for producers     | 295            | Amarasekare 2015     |
| T_opt_invertebrate         | temperature at which trait value is maximal for invertebrates | 295            | Amarasekare 2015     |
| T_opt_vertebrate           | temperature at which trait value is maximal for vertebrates   | 295            | Amarasekare 2015     |
| β_producer                 | allometric exponent for producers                             | -0.25          | Gillooly et al 2002  |
| β_invertebrate             | allometric exponent for invertebrates                         | -0.25          | Gillooly et al 2002  |
| β_vertebrate               | allometric exponent for vertebrates                           | -0.25          | Gillooly et al 2002  |
| range_producer             | performance breath (width of function) for producers          | 20             | Amarasekare 2015     |
| range_invertebrate         | performance breath (width of function) for invertebrates      | 20             | Amarasekare 2015     |
| range_vertebrate           | performance breath (width of function) for vertebrates        | 20             | Amarasekare 2015     |


Example:
metabolicrate=gaussian_x(@NT(norm_constant_producer = 0.5, norm_constant_invertebrate = 0.5, norm_constant_vertebrate = 0.5,
                             range_producer = 20, range_invertebrate = 20, range_vertebrate = 20,
                             T_opt_producer = 295, T_opt_invertebrate = 295, T_opt_vertebrate = 295,
                             β_producer = -0.25, β_invertebrate = -0.25, β_vertebrate = -0.25))

"""
function gaussian_x(default_temp_parameters = @NT(norm_constant_producer = 0.5, norm_constant_invertebrate = 0.5, norm_constant_vertebrate = 0.5,
                             range_producer = 20, range_invertebrate = 20, range_vertebrate = 20,
                             T_opt_producer = 295, T_opt_invertebrate = 295, T_opt_vertebrate = 295,
                             β_producer = -0.25, β_invertebrate = -0.25, β_vertebrate = -0.25); passed_temp_parameters...)
	if length(passed_temp_parameters) != 0
	  tmpargs = passed_temp_parameters[:passed_temp_parameters]
	  temperature_param = merge(default_temp_parameters, tmpargs)
	else
	  temperature_param = default_temp_parameters
	end

     return(bodymass, T, p) -> for i in 1:1
                                 norm_constant_all = temperature_param.norm_constant_producer .* p[:is_producer] .+ temperature_param.norm_constant_vertebrate .* p[:vertebrates] .+ temperature_param.norm_constant_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                 T_opt_all = temperature_param.T_opt_producer .* p[:is_producer] .+ temperature_param.T_opt_vertebrate .* p[:vertebrates] .+ temperature_param.T_opt_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                 β_all = temperature_param.β_producer .* p[:is_producer] .+ temperature_param.β_vertebrate .* p[:vertebrates] .+ temperature_param.β_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                 range_all = temperature_param.range_producer .* p[:is_producer] .+ temperature_param.range_vertebrate .* p[:vertebrates] .+ temperature_param.range_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                 return bodymass.^β_all .* norm_constant_all .* exp.(.-(T .- T_opt_all).^2 ./ (2 .*range_all.^2))
                               end
end


"""
**Option 4 : Gaussian function for attack rate**

| Parameter                  | Meaning                                                       | Default values | Reference            |
|:---------------------------|:--------------------------------------------------------------|:---------------|:---------------------|
| shape                      | hump-shaped (:hump) or U-shaped (:U) curve                    | :hump          | Amarasekare 2015     |
| norm_constant_invertebrate | minimal/maximal trait value for invertebrates                 | 0.5            | NA                   |
| norm_constant_vertebrate   | minimal/maximal trait value for vertebrates                   | 0.5            | NA                   |
| range_invertebrate         | performance breath (width of function) for invertebrates      | 20             | Amarasekare 2015     |
| range_vertebrate           | performance breath (width of function) for vertebrates        | 20             | Amarasekare 2015     |
| T_opt_invertebrate         | temperature at which trait value is maximal                   | 295            | Amarasekare 2015     |
| T_opt_vertebrate           | temperature at which trait value is maximal for invertebrates | 295            | Amarasekare 2015     |
| β_producer                 | allometric exponent for producers                             | -0.25          | Gillooly et al 2002  |
| β_invertebrate             | allometric exponent for invertebrates                         | -0.25          | Gillooly et al 2002  |
| β_vertebrate               | allometric exponent for vertebrates                           | -0.25          | Gillooly et al 2002  |

Default values are given as an example for attack rate.

Example:
attackrate=gaussian_functionalr(@NT(shape = :hump,
                                    norm_constant_invertebrate = 0.5, norm_constant_vertebrate = 0.5,
                                    range_invertebrate = 20, range_vertebrate = 20,
                                    T_opt_invertebrate = 295, T_opt_vertebrate = 295,
                                    β_producer = -0.25, β_invertebrate = -0.25, β_vertebrate = -0.25))

"""

function gaussian_attackr(default_temp_parameters = @NT(shape = :hump,
                                    norm_constant_invertebrate = 0.5, norm_constant_vertebrate = 0.5,
                                    range_invertebrate = 20, range_vertebrate = 20,
                                    T_opt_invertebrate = 295, T_opt_vertebrate = 295,
                                    β_producer = -0.25, β_invertebrate = -0.25, β_vertebrate = -0.25); passed_temp_parameters...)
	if length(passed_temp_parameters) != 0
	  tmpargs = passed_temp_parameters[:passed_temp_parameters]
	  temperature_param = merge(default_temp_parameters, tmpargs)
	else
	  temperature_param = default_temp_parameters
	end

	return(bodymass, T, p) -> for i in 1:1
                                norm_constant_all = temperature_param.norm_constant_vertebrate .* p[:vertebrates] .+ temperature_param.norm_constant_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                T_opt_all = temperature_param.T_opt_vertebrate .* p[:vertebrates] .+ temperature_param.T_opt_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                β_consumer = temperature_param.β_vertebrate .* p[:vertebrates] .+ temperature_param.β_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                range_all = temperature_param.range_vertebrate .* p[:vertebrates] .+ temperature_param.range_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                # β for resources
                                β_resource = zeros(Float64,(p[:S], p[:S]))
                                for consumer in 1:p[:S]
                                for resource in 1:p[:S]
                                  if p[:A][consumer, resource] == 1
                                    if p[:is_producer][resource]
                                        β_resource[consumer, resource] = temperature_param.β_producer
                                    elseif p[:vertebrates][resource]
                                        β_resource[consumer, resource] = temperature_param.β_vertebrate
                                    else
                                        β_resource[consumer, resource] = temperature_param.β_invertebrate
                                    end
                                 end
                                end
                                end

                                if temperature_param.shape == :hump
                                    rate = bodymass.^β_consumer .* bodymass'.^β_resource .* norm_constant_all .* exp.(.-(T .- T_opt_all).^2 ./ (2 .*range_all.^2))
                                elseif temperature_param.shape == :U
                                    rate = bodymass.^β_consumer .* bodymass'.^β_resource .* norm_constant_all .* exp.((T .- T_opt_all).^2 ./ (2 .*range_all.^2))
                                end
                                rate[isnan.(rate)] = 0
                                return rate
                            end
end

"""
**Option 4 : Gaussian function for functional response**

| Parameter                  | Meaning                                                       | Default values | Reference            |
|:---------------------------|:--------------------------------------------------------------|:---------------|:---------------------|
| shape                      | hump-shaped (:hump) or U-shaped (:U) curve                    | :hump          | Amarasekare 2015     |
| norm_constant_invertebrate | minimal/maximal trait value for invertebrates                 | 0.5            | NA                   |
| norm_constant_vertebrate   | minimal/maximal trait value for vertebrates                   | 0.5            | NA                   |
| range_invertebrate         | performance breath (width of function) for invertebrates      | 20             | Amarasekare 2015     |
| range_vertebrate           | performance breath (width of function) for vertebrates        | 20             | Amarasekare 2015     |
| T_opt_invertebrate         | temperature at which trait value is maximal                   | 295            | Amarasekare 2015     |
| T_opt_vertebrate           | temperature at which trait value is maximal for invertebrates | 295            | Amarasekare 2015     |
| β_producer                 | allometric exponent for producers                             | -0.25          | Gillooly et al 2002  |
| β_invertebrate             | allometric exponent for invertebrates                         | -0.25          | Gillooly et al 2002  |
| β_vertebrate               | allometric exponent for vertebrates                           | -0.25          | Gillooly et al 2002  |

Default values are given as an example for attack rate.

Example:
attackrate=gaussian_functionalr(@NT(shape = :hump,
                                    norm_constant_invertebrate = 0.5, norm_constant_vertebrate = 0.5,
                                    range_invertebrate = 20, range_vertebrate = 20,
                                    T_opt_invertebrate = 295, T_opt_vertebrate = 295,
                                    β_producer = -0.25, β_invertebrate = -0.25, β_vertebrate = -0.25))

"""

function gaussian_handlingt(default_temp_parameters = @NT(shape = :U,
                                    norm_constant_invertebrate = 0.5, norm_constant_vertebrate = 0.5,
                                    range_invertebrate = 20, range_vertebrate = 20,
                                    T_opt_invertebrate = 295, T_opt_vertebrate = 295,
                                    β_producer = -0.25, β_invertebrate = -0.25, β_vertebrate = -0.25); passed_temp_parameters...)
	if length(passed_temp_parameters) != 0
	  tmpargs = passed_temp_parameters[:passed_temp_parameters]
	  temperature_param = merge(default_temp_parameters, tmpargs)
	else
	  temperature_param = default_temp_parameters
	end

	return(bodymass, T, p) -> for i in 1:1
                                norm_constant_all = temperature_param.norm_constant_vertebrate .* p[:vertebrates] .+ temperature_param.norm_constant_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                T_opt_all = temperature_param.T_opt_vertebrate .* p[:vertebrates] .+ temperature_param.T_opt_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                β_consumer = temperature_param.β_vertebrate .* p[:vertebrates] .+ temperature_param.β_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                range_all = temperature_param.range_vertebrate .* p[:vertebrates] .+ temperature_param.range_invertebrate .* (.!p[:vertebrates] .& .!p[:is_producer])
                                # β for resources
                                β_resource = zeros(Float64,(p[:S], p[:S]))
                                for consumer in 1:p[:S]
                                for resource in 1:p[:S]
                                  if p[:A][consumer, resource] == 1
                                    if p[:is_producer][resource]
                                        β_resource[consumer, resource] = temperature_param.β_producer
                                    elseif p[:vertebrates][resource]
                                        β_resource[consumer, resource] = temperature_param.β_vertebrate
                                    else
                                        β_resource[consumer, resource] = temperature_param.β_invertebrate
                                    end
                                 end
                                end
                                end

                                if temperature_param.shape == :hump
                                    rate = bodymass.^β_consumer .* bodymass'.^β_resource .* norm_constant_all .* exp.(.-(T .- T_opt_all).^2 ./ (2 .*range_all.^2))
                                elseif temperature_param.shape == :U
                                    rate = bodymass.^β_consumer .* bodymass'.^β_resource .* norm_constant_all .* exp.((T .- T_opt_all).^2 ./ (2 .*range_all.^2))
                                end
                                rate[isnan.(rate)] = 0
                                return rate
                            end
end
