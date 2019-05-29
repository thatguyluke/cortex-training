CORTEX_CLI = cortex

AGENT_NAME := $(shell jq '.name' agent.json)

save: agent.json
	$(CORTEX_CLI) agents save agent.json

register: save connect

connect: auto-wire
	$(CORTEX_CLI) agents save auto-agent.json
	# - [ ] Bug .. need to double save to get this to work ...
	bash connect-agent.sh
	$(CORTEX_CLI) agents save auto-agent.json

auto-wire:
	bash connect-agent.sh

# This is not to be used until cron is enabled on agent
restart:
	# Turn off all started agent instance ...
	cortex agents list-instances ${AGENT_NAME} --json | jq -r '.[] | select(.status == "started") | .id' \
		| xargs -I {} cortex agents stop-instance {}
	# Create a new agent instance
	cortex agents create-snapshot --color=off --agentName "${AGENT_NAME}" --title "CronSnapshot" | jq -r '.snapshotId' \
		| xargs -I {} cortex agents create-instance --snapshotId {} --environmentName cortex/default
