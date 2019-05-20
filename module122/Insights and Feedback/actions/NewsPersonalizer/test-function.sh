#!/usr/bin/env bash
set -e
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${SCRIPT_DIR}/../../common.sh

PARAMS=$(cat "${SCRIPT_DIR}/test/test_req.json" | jq -c --arg apiEndpoint "${CORTEX_API_ENDPOINT}" --arg token "${CORTEX_JWT_TOKEN}" ' (.token |= $token) | (.apiEndpoint |= $apiEndpoint)')
cortex actions invoke ${INSIGHTS_ACTION_NAME} --params "${PARAMS}"
