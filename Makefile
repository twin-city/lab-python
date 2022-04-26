export IMAGE_NAME=twin-city
export PROJECT_NAME=twincity
export APP_PATH := $(shell pwd)
export VERSION := v0.1
export USER := $(shell whoami)
export NB_GPUS := 0
export NB_CPUS := 2 # this value is ignored if NB_GPUS is specified.
export REGION := gra
export PROJECT_DATA_RIGHTS := rwd
export JOB=$(cat job.json | jq '.id')

dummy	:= $(shell touch artifacts)
include ./artifacts
# build locally the docker image
build:
	docker build -t $(IMAGE_NAME) .
run-locally:build
	docker run --rm -it -v ${APP_PATH}/group:/etc/group -v ${APP_PATH}/passwd:/etc/passwd --user=ovh:ovh $(IMAGE_NAME)

# Deploy job to ovh
deploy-job:
	ovhai job run \
		--gpu ${NB_GPUS} \
		--cpu ${NB_CPUS} \
		--name ${PROJECT_NAME}-${USER}-${NB_GPUS}GPU-${NB_CPUS}CPU \
		--label user=${USER}\
		--volume ${PROJECT_NAME}-home@${REGION}:/workspace/home:${PROJECT_DATA_RIGHTS} \
		--output json \
		ghcr.io/datalab-mi/${IMAGE_NAME}:${VERSION} > job.json \
		$(command)
	@cat job.json | jq '.status.jobUrl'

#usage: for a specific job do 'make stop-job JOB=xxxxx' else read the last file job.json
stop-job:
	ovhai job stop $(JOB)

list-job:
	ovhai job list

# open the job in notebook
jobid=$(grep -Po '"id":.*?[^\\]"' job.json |awk -F':' '{print $2}')
open-job:
	@echo $(jobid)

data-upload:
	ovhai data upload ${REGION} $(DST) $(SRC)
