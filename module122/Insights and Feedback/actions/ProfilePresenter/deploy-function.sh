#!/usr/bin/env bash
set -e
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ${SCRIPT_DIR}/../../common.sh

# Deploy our function to Cortex
cortex actions deploy ${PROFILES_ACTION_NAME} --docker ${FPI_COURSE_PROFILES_REMOTE_IMAGE_NAME}
