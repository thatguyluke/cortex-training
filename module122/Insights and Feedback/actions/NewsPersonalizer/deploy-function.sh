#!/usr/bin/env bash
set -e
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ${SCRIPT_DIR}/../../common.sh

# Deploy our function to Cortex
cortex actions deploy ${INSIGHTS_ACTION_NAME} --docker ${FPI_COURSE_INSIGHTS_REMOTE_IMAGE_NAME}
