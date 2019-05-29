#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${CURRENT_DIR}

function recursive_delete(){
	# $1 key we want to delete recursively
	jq "import \"lib\" as lib; lib::walk(if type == \"object\" then del(.[\"${1}\"]) else . end)"

}

function pluck_agent_input_signal_id() {
	# $1 is name of input channel
	jq -r ".inputs | map(select(.name == \"${1}\")) | .[0].signalId"
}

function pluck_agent_output_signal_id() {
	# $1 is name of output channel
	jq -r ".outputs | map(select(.name == \"${1}\")) | .[0].signalId"
}

function pluck_skill_ref_id() {
	# $1 is name of skill
	jq -r ".skills | map(select(.title == \"${1}\")) | .[0].refId"
}

function connect_agent_input_to_skill(){
	# $1 is signalId for agent input
	# $2 is refId for the skill
	# $3 is input channel for skill
	# $4 is mapping rules
	jq -r \
		--arg AGENT_INPUT_SIGNAL_ID "${1}" \
		--arg SKILL_REF_ID "${2}" \
		--arg SKILL_INPUT_CHANNEL "${3}" \
		--argjson MAPPING_RULES "${4}" \
		'.mappings += [{"from":{"input":{"signalId":$AGENT_INPUT_SIGNAL_ID}},"to":{"skill":{"refId":$SKILL_REF_ID,"input":$SKILL_INPUT_CHANNEL}},"rules":$MAPPING_RULES}]'
}

function connect_skill_to_agent_output(){
	# $1 is refId for skill
	# $2 is output channel for skill
	# $3 is signalId for agent output
	# $4 is mapping rules
	jq -r \
		--arg SKILL_REF_ID "${1}" \
		--arg SKILL_OUTPUT_CHANNEL "${2}" \
		--arg AGENT_OUTPUT_SIGNAL_ID "${3}" \
		--argjson MAPPING_RULES "${4}" \
		'.mappings += [{"from":{"skill":{"refId":$SKILL_REF_ID,"output":$SKILL_OUTPUT_CHANNEL}},"to":{"output":{"signalId":$AGENT_OUTPUT_SIGNAL_ID}},"rules":$MAPPING_RULES}]'
}

function connect_skill_to_another_skill(){
	# $1 is refId for skill outputing
	# $2 is output channel for skill
	# $3 is refId for skill inputting
	# $4 is input channel for skill
	# $5 is mapping rules
	jq -r \
		--arg OUTPUTTING_SKILL_REF_ID "${1}" \
		--arg OUTPUTTING_SKILL_OUTPUT_CHANNEL "${2}" \
		--arg INPUTTING_SKILL_REF_ID "${3}" \
		--arg INPUTTING_SKILL_INPUT_CHANNEL "${4}" \
		--argjson MAPPING_RULES "${5}" \
		'.mappings += [{"from":{"skill":{"refId":$OUTPUTTING_SKILL_REF_ID,"output":$OUTPUTTING_SKILL_OUTPUT_CHANNEL}},"to":{"skill":{"refId":$INPUTTING_SKILL_REF_ID,"input":$INPUTTING_SKILL_INPUT_CHANNEL}},"rules":$MAPPING_RULES}]'
}

function cleanup_agent_def() {
	jq "del(._version, ._tenantId, .updatedAt, .tags, .properties, .createdAt, ._updatedAt, ._createdAt, .__v, ._environmentId)" \
		| recursive_delete "_id" \
		| recursive_delete "_layout"
}

function connect_agent(){
	CURRENT_PROFILE=$(cat ~/.cortex/config | jq -r ".currentProfile")
	JWT_TOKEN=$(cat ~/.cortex/config | jq ".profiles" | jq ".[\"${CURRENT_PROFILE}\"]" | jq -r ".token")
	CORTEX_API_ENDPOINT=$(cat ~/.cortex/config | jq ".profiles" | jq ".[\"${CURRENT_PROFILE}\"]" | jq -r ".url")
	
	AGENT_NAME=$(cat ${CURRENT_DIR}/agent.json | jq -r '.name')
	echo Wiring =$AGENT_NAME=

	AGENT_DEF=$(curl -s -X GET ${CORTEX_API_ENDPOINT}/v3/catalog/agents/${AGENT_NAME} -H "authorization: Bearer ${JWT_TOKEN}" -H 'content-type: application/json' | jq .) 
	# echo "${AGENT_DEF}" | jq .
	
	AGENT_INPUT_INSIGHTS=$(echo ${AGENT_DEF} | pluck_agent_input_signal_id "insightsAPI")
	AGENT_INPUT_FEEDBACK=$(echo ${AGENT_DEF} | pluck_agent_input_signal_id "feedbackAPI")
	AGENT_INPUT_PROFILES=$(echo ${AGENT_DEF} | pluck_agent_input_signal_id "profilesAPI")
	echo "Agent Inputs: ${AGENT_INPUT_INSIGHTS}, ${AGENT_INPUT_FEEDBACK}, ${AGENT_INPUT_PROFILES}"

	AGENT_OUPUT_INSIGHTS=$(echo ${AGENT_DEF} | pluck_agent_output_signal_id "insight_generation")
	AGENT_OUPUT_FEEDBACK=$(echo ${AGENT_DEF} | pluck_agent_output_signal_id "feedback_processing")
	AGENT_OUPUT_PROFILES=$(echo ${AGENT_DEF} | pluck_agent_output_signal_id "profile_presentation")
	echo "Agent Outputs: ${AGENT_OUPUT_INSIGHTS}, ${AGENT_OUPUT_FEEDBACK}, ${AGENT_OUPUT_PROFILES}"

	SKILL_INSIGHTS=$(echo ${AGENT_DEF} | pluck_skill_ref_id "NewsPersonalizer")
	SKILL_FEEDBACK=$(echo ${AGENT_DEF} | pluck_skill_ref_id "FeedbackHandler")
	SKILL_PROFILES=$(echo ${AGENT_DEF} | pluck_skill_ref_id "ProfilePresenter")
	echo "Skills: ${SKILL_INSIGHTS}, ${SKILL_FEEDBACK}, ${SKILL_PROFILES}"

	echo "${AGENT_DEF}" \
		| cleanup_agent_def \
		| jq '.mappings = []' \
		| connect_agent_input_to_skill "${AGENT_INPUT_INSIGHTS}" "${SKILL_INSIGHTS}" "personalization_request" "[]" \
		| connect_agent_input_to_skill "${AGENT_INPUT_FEEDBACK}" "${SKILL_FEEDBACK}" "insights_liked" "[]" \
		| connect_agent_input_to_skill "${AGENT_INPUT_PROFILES}" "${SKILL_PROFILES}" "presentation_request" "[]" \
		| connect_skill_to_agent_output  "${SKILL_INSIGHTS}"   "insights" "${AGENT_OUPUT_INSIGHTS}" "[]" \
		| connect_skill_to_agent_output  "${SKILL_FEEDBACK}" "feedback_ingestion_complete" "${AGENT_OUPUT_FEEDBACK}" "[]" \
		| connect_skill_to_agent_output  "${SKILL_PROFILES}" "profile_presentation" "${AGENT_OUPUT_PROFILES}" "[]" \
		| jq . \
		> auto-agent.json
	
	echo "Auto Wired Agent [${AGENT_NAME}]"
}

connect_agent
