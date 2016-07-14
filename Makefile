NAME=befwm
V=0.4
FOLD=~/.julia/v$(V)/$(NAME)

.PHONY: clean help

.DEFAULT_GOAL := help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

clean: ## Clean the test directory and remove test artifacts
	- rm src/*cov

install: src/*jl test/*jl ## Install the package in the specified julia version (removes before if already present)
	-julia -e 'Pkg.rm("$(NAME)")'
	-julia -e 'Pkg.clone(pwd())'

test: install ## Run the tests (including code coverage informations)
	julia --code-coverage test/runtests.jl

coverage: test ## Perform the code coverage analysis
	cd $(FOLD); julia -e 'Pkg.add("Coverage"); using Coverage; coverage = process_folder(); covered_lines, total_lines = get_summary(coverage); println(round(covered_lines/total_lines*100,2),"% covered")'

doc: install ## Self-document the code and copy into the doc/ subfolder
	cp {CHANGELOG,LICENSE}.md docs/src/
	cd docs && julia make.jl
	cd docs && mkdocs build --clean
	cp -r docs/site/* ~/code/web/poisotlab.github.io/doc/befwm/

mirror: ## Pushes to the github mirror
	git push --mirror git@github.com:PoisotLab/befwm.jl.git
