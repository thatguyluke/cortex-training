#!/usr/bin/env bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${SCRIPT_DIR}/../../common.sh

cd ${SCRIPT_DIR} && docker build -t "${FPI_COURSE_PROFILES_DOCKER_IMAGE_NAME}" -f ${FPI_COURSE_PROFILES_DOCKERFILE} . 
