# This is called a conditional variable assignment operator, because it only has an effect if the variable is not yet defined.

# ifeq ($(origin FOO), undefined)
#   FOO = bar
# endif

# ANIMAL=FROG
# VAR:="${ANIMAL} DOG CAT"
# ANIMAL=PORCUPINE

# test:
# 	@echo $(VAR)

# output -> FROG DOG CAT -> This means that the variable is expanded at the time of assignment.

.PHONY: help

SHELL:=bash
REGISTRY?=quay.io
OWNER?=jupyter

ALL_IMAGES:= \
		base

# Enable BuildKit for Docker build
export DOCKER_BUILDKIT:=1

# -E -> Enables Extended Regular Expression (ERE) mode for searching regex patterns
# ^ Matches the beginning of the string, or the beginning of the line
# + matches one or more the preceeding token
# matches : character
help:
	@echo "opencadc/science-containers"
	@echo "==========================="
	@echo "Replace % with a stack directory name (e.g., make build/base)"
	@echo
	@grep -E '^[a-zA-Z0-9_%/-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# % is used as a wildcard
# --rm flag tells the Docker Daemon to clean up the container and remove the file system after the container exits.
# --force-rm flag always remove intermediate container
# intermediate containers are created when Docker builds each layer of the image. These containers are temporary and are used to execute commands in each step of the Dockerfile. Once a layer is complete, Docker saves it as a new image and discards the intermediate containers.
# target: prereuisites
# 		recipe
# ‘$@’ is the name of whichever target caused the rule’s recipe to be run. 

# dummy/base:
# 	@echo $(notdir $@) -> Outputs base
build/%: DOCKER_BUILD_ARGS?=
build/%: ## build the latest image for a stack using the system's architecuture
		 docker build $(DOCKER_BUILD_ARGS) --rm --force-rm --tag "$(REGISTRY)/$(OWNER)/$(notdir $@):latest" "./images/$(notdir $@)" --build-arg REGISTRY="$(REGISTRY)" --build-arg OWNER="$(OWNER)"
		 @echo -n "BUILT image size: "
		 @docker images "$(REGISTRY)/$(OWNER)/$(notdir $@):latest" --format "{{.Size}}"
build-all: $(foreach I, $(ALL_IMAGES), build/$(I)) # build all stacks

# The > operator redirects the output usually to a file but it can be to a device. You can also use >> to append
# 2> file redirects stderr to file
# /dev/null is the null device it takes any input you want and throws it away. It can be used to suppress any output


# why the `-docker` ? 
cont-clean-all: cont-stop-all cont-rm-all ## clean all containers (stop + rm)
cont-stop-all: ##stopping all containers
	@echo "Stopping all containers ..."
	-docker stop --time 0 $(shell docker ps --all --quiet) 2> /dev/null
cont-rm-all: ##remove all containers
	@echo "Removing all containers ..."
	-docker rm --force $(shell docker ps -all --quiet) 2> /dev/null

img-clean: img-rm-dang img-rm ## clean dangling and jupyter images
img-list: ## list jupyter images
	@echo "Listing $(OWNER) images ..."
	docker images "$(OWNER)/*"
	docker images "*/$(OWNER)/*"
img-rm: ## remove jupyter images
	@echo "Removing $(OWNER) images ..."
	-docker rmi --force $(shell docker images --quiet "$(OWNER)/*") 2> /dev/null
	-docker rmi --force $(shell docker images --quiet "*/(OWNER)/*") 2> /dev/null
img-rm-dang: ## remove dangling images (tagged None)
	@echo "Remove dangling images ..."
	-docker rmi --force $(shell docker images -f "dangling=true" --quiet) 2> /dev/null

push/%: ## push all tags for a jupyter images
	docker push --all-tags "$(REGISTRY)/$(OWNER)/$(notdir $@)"
push-all: $(foreach I, $(ALL_IMAGES), push/$(I)) ## push all tagged images

# -it is short for --interactive + --tty. When you docker run with this command it takes you straight inside the container.

# The --rm flag tells docker that the container should automatically be removed after we close docker

# $(SHELL) -> /bin/bash

run-shell/%: ## run a bash in interactive mode in a stack
	docker run -it --rm "$(REGISTRY)/$(OWNER)/$(notdir $@)" $(SHELL)
run-sudo-shell/%: ## run a bash in interactive mode as root in a stack
	docker run -it --rm --user root "$(REGISTRY)/$(OWNER)/$(notdir $@)" $(SHELL)
