#!/usr/bin/env bash
set -e
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Run the build
${SCRIPT_DIR}/build-function.sh

# Deploy our function to Cortex
cortex actions deploy class/movie-maker-cli-YOUR_INITIALS --code "${SCRIPT_DIR}/build/function.zip" --kind python:3
