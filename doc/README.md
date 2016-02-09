# Bio-energetic Food Web Model

The `befwm` package for [Julia][julia] offers an interface to perform
simulation of the bioenergetic model of Yodzis and Innes {{ "yodzis-innes"
| cite }} as applied to food webs {{ "brose" | cite }}.

[julia]: http://julialang.org

The model uses `Sundials.jl` to perform robust and precise numerical
integration.

## Installation

The latest version of the package can be downloaded from [our GitLab
server][glab]. Once downloaded, navigate to where it was extracted, and
either use `make install`, or start julia, and type

~~~ julia
Pkg.clone(pwd())
~~~

This should take care of installing the dependencies (only `Sundials`)
is required.

[glab]: http://132.204.122.203/tpoisot/befwm/repository/archive.zip?ref=master

## References

{% references %} {% endreferences %}