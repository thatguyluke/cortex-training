#!/usr/bin/env bash

export CURRENT_PROFILE=$(cat ${HOME}/.cortex/config | jq -r ".currentProfile")
export CORTEX_API_ENDPOINT=$(cat ${HOME}/.cortex/config | jq -r ".profiles | .[\"${CURRENT_PROFILE}\"] | .url")
export CORTEX_JWT_TOKEN=$(cat ${HOME}/.cortex/config | jq ".profiles" | jq ".[\"${CURRENT_PROFILE}\"]" | jq -r ".token")

function determine_registry() {
	echo ${CORTEX_API_ENDPOINT} \
		| egrep -o 'cortex(-[a-z]+)?' \
		| xargs -I {} echo "registry.{}.insights.ai:5000"
}

function determine_version_from_git() {
	git describe --long --always --dirty --match='v*.*' | sed 's/v//; s/-/./'
}


export REMOTE_IMAGE_PROXY="$(determine_registry)"

export INSIGHTS_ACTION_NAME="fpi/NewsPersonalizer"
export FEEDBACK_ACTION_NAME="fpi/FeedbackHandler"
export PROFILES_ACTION_NAME="fpi/ProfilePresenter"

export -f determine_registry
export -f determine_version_from_git

export FPI_COURSE_INSIGHTS_DOCKERFILE=Dockerfile.c12e-ci.cortex-skill-news-personalizer
export FPI_COURSE_FEEDBACK_DOCKERFILE=Dockerfile.c12e-ci.cortex-skill-feedback-handler
export FPI_COURSE_PROFILES_DOCKERFILE=Dockerfile.c12e-ci.cortex-skill-profile-presenter

export FPI_COURSE_INSIGHTS_DOCKER_IMAGE_NAME=c12e/cortex-skill-news-personalizer:latest-dev
export FPI_COURSE_FEEDBACK_DOCKER_IMAGE_NAME=c12e/cortex-skill-feedback-handler:latest-dev
export FPI_COURSE_PROFILES_DOCKER_IMAGE_NAME=c12e/cortex-skill-profile-presenter:latest-dev

export FPI_COURSE_INSIGHTS_REMOTE_IMAGE_NAME=${REMOTE_IMAGE_PROXY}/${FPI_COURSE_INSIGHTS_DOCKER_IMAGE_NAME}
export FPI_COURSE_FEEDBACK_REMOTE_IMAGE_NAME=${REMOTE_IMAGE_PROXY}/${FPI_COURSE_FEEDBACK_DOCKER_IMAGE_NAME}
export FPI_COURSE_PROFILES_REMOTE_IMAGE_NAME=${REMOTE_IMAGE_PROXY}/${FPI_COURSE_PROFILES_DOCKER_IMAGE_NAME}
