#!/usr/bin/env bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${SCRIPT_DIR}/../../common.sh

REQUEST_FILE=${1:-${SCRIPT_DIR}/test/test_req.json}

${SCRIPT_DIR}/build-container-locally.sh 1>/dev/null 2>/dev/null

cat ${REQUEST_FILE} \
	| jq -c --arg apiEndpoint "${CORTEX_API_ENDPOINT}" --arg token "${CORTEX_JWT_TOKEN}" ' (.token |= $token) | (.apiEndpoint |= $apiEndpoint)' \
	| docker run -i ${FPI_COURSE_INSIGHTS_DOCKER_IMAGE_NAME}
