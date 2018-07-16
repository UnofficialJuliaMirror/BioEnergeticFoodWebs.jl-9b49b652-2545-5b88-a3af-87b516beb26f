"""
**Functions of thermal performance curve for model parameters**

We included different functions of temperature dependence : 1) Extended Eppley function
                                                            2) Quadratic function
                                                            3) Exponential Boltzmann-Arrhenius function
                                                            4) Extended Boltzmann-Arrhenius function (Johnson-Lewin)
                                                            5) Gaussian (inverted Gaussian) function

In each case, the function returns the biological rate value at a given temperature.

"""

"""

**Option 1 : Extended Eppley function**

| Parameter    | Meaning                                                           |
|:-------------|:------------------------------------------------------------------|
| temp         | temperature range (Celsius degree)                                |
| a            | parameter from the Eppley curve for the growth phase              |
| b            | parameter from the Eppley curve for the growth phase              |
| z            | location of the maximum of the quadratic portion of the function  |
| w            | thermal breadth                                                   |
| p[:bodymass] | body mass                                                         |
| beta         | allometric exponent                                               |


No temperature effect :

a=1
b=0
z=18
w=35
p[:bodymass]=1
beta=-0.25

To account for a temperature effect, the parameters are for instance :
    a=0.81
    b=0.0631 (parameters from the Eppley curve)
    z=18
    w=35
    p[:bodymass]=1
    beta=-0.25
"""

function extended_eppley(para_extended_eppley, p)
    temp=para_extended_eppley[1]
    a=para_extended_eppley[2]
    b=para_extended_eppley[3]
    z=para_extended_eppley[4]
    w=para_extended_eppley[5]
    beta=para_extended_eppley[6]

    return p[:bodymass]^beta*a.*exp.(b.*temp).*(1-((temp-z)./(w/2)).^2)

end

"""
**Option 2 : Quadratic function**

| Parameter    | Meaning                                                                                  |
|:-------------|:-----------------------------------------------------------------------------------------|
| temp         | temperature range (Kelvin)                                                               |
| b            | fitted parameter from Englund et al (2011), determines the shape of the thermal response |
| q            | fitted parameter from Englund et al (2011), determines the shape of the thermal response |
| c            | fitted parameter from Englund et al (2011)                                               |
| p[:bodymass] | body mass                                                                                |
| beta         | allometric exponent                                                                      |
| k            | Boltzmann constant (k=8.617e-5)                                                          |                                                            |

Parameters are for instance (parametrization to revise):

c=0.2
q=-0.5
b=-1.6537077869328072e6
p[:bodymass]=1
beta=-0.25
"""

function quadratic(para_quadratic)
    temp=para_quadratic[1]
    c=para_quadratic[2]
    b=para_quadratic[3]
    q=para_quadratic[4]
    beta=para_quadratic[5]
    k=8.617e-5
    return p[:bodymass]^beta*c*exp(b*(-1/k*temp)+q*(-1/k*temp)^2)

end

"""
**Option 3 : Exponential Boltzmann-Arrhenius function**

| Parameter    | Meaning                               |
|:-------------|:--------------------------------------|
| temp         | temperature range (Kelvin)            |
| p0           | scaling coefficient                   |
| E            | activation energy                     |
| p[:bodymass] | body mass                             |
| beta         | allometric exponent                   |
| k            | Boltzmann constant (k=8.617e-5)       |

Parameters are for instance:

p0=0.2e11
E=0.65
m=1
beta=-0.25

"""

function exponential_BA(para_exponential_BA,p)
    temp=para_exponential_BA[1]
    p0=para_exponential_BA[2]
    E=para_exponential_BA[3]
    beta=para_exponential_BA[4]

    k=8.617e-5 # Boltzmann constant

    return p0.*p[:bodymass].^beta.*exp.(-E./(k*temp))

end

"""
**Option 4 : Extended Boltzmann-Arrhenius function**

| Parameter     | Meaning                                               |
|:--------------|:------------------------------------------------------|
| temp          | temperature range (Kelvin)                            |
| p0            | scaling coefficient                                   |
| E             | activation energy                                     |
| Ed            | deactivation energy                                   |
| topt          | temperature at which trait value is maximal           |
| p[:bodymass]  | body mass                                             |
| beta          | allometric exponent                                   |
| k             | Boltzmann constant (k=8.617e-5)                       |

Parameters are for instance:

p0=0.2e12
E=0.65
Ed=0.72
topt=295
p[:bodymass]=1
beta=-0.25


"""

function extended_BA(para_extended_BA, p)
    temp=para_extended_BA[1]
    p0=para_extended_BA[2]
    E=para_extended_BA[3]
    Ed=para_extended_BA[4]
    topt=para_extended_BA[5]
    beta=para_extended_BA[6]
    k=8.617e-5 # Boltzmann constant
                                             |

    lT=1/(1+exp(-1/(k*temp)*(Ed-(Ed/topt+k*log(E/(Ed-E)))*temp)))
    return p0*p[:bodymass]^beta*exp(-E/(k*temp))*lT

end


"""
**Option 5 : Gaussian function**

| Parameter    | Meaning                                        |
|:-------------|:-----------------------------------------------|
| temp         | temperature range (Kelvin)                     |
| p0           | minimal/maximal trait value                    |
| s            | performance breath (width of function)         |
| topt         | temperature at which trait value is maximal    |
| p[:bodymass] | body mass                                      |
| beta         | allometric exponent                            |

Parameters are for instance:

p0=0.5
s=20
topt=295
p[:bodymass]=1
beta=-0.25

"""

function gaussian(para_gaussian, p, Ushape=0)
    temp=para_gaussian[1]
    p0=para_gaussian[2]
    s=para_gaussian[3]
    topt=para_gaussian[4]
    beta=para_gaussian[5]

    if Ushape == 0
        return p[:bodymass].^beta.*p0.*exp.(-(temp-topt)^2/(2*s^2))
    elseif Ushape == 1
        return  p[:bodymass].^beta.*p0.*exp.((temp-topt)^2/(2*s^2))
    end
end
