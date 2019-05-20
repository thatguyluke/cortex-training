#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load all the data ... into Managed Content
cortex content upload newsAgent/datasets/newsArticles.json data/datasets/newsArticles.json
cortex content upload newsAgent/datasets/topics.json data/datasets/topics.json
cortex content upload newsAgent/datasets/feedback.json data/datasets/feedback.json
cortex content upload newsAgent/datasets/insights.json data/datasets/insights.json
cortex content upload newsAgent/profiles/tom.json data/profiles/tom.json
cortex content upload newsAgent/profiles/jim.json data/profiles/jim.json

# Load all the types ...
find ${SCRIPT_DIR}/types -type f -exec cortex types save {} \;

# Load all the connections ...

# Load all the datasets ...
find ${SCRIPT_DIR}/datasets -type f -exec cortex datasets save {} \;

# Load all the skills ...
find ${SCRIPT_DIR}/skills -type f -exec cortex skills save -y {} \;

# Load all the agent(s) ...
(cd agent && make register)

# Deploy Actions
find ${SCRIPT_DIR}/actions -type f -name 'deploy-function.sh' -exec bash {} \;
# cortex actions deploy ${FEEDBACK_ACTION_NAME} --docker ${FPI_COURSE_FEEDBACK_REMOTE_IMAGE_PROXY}
# cortex actions deploy ${INSIGHTS_ACTION_NAME} --docker ${FPI_COURSE_INSIGHTS_REMOTE_IMAGE_PROXY}
# cortex actions deploy ${PROFILES_ACTION_NAME} --docker ${FPI_COURSE_PROFILES_REMOTE_IMAGE_PROXY}
