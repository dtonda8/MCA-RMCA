#!/bin/bash

./build/MAPD \
	-m examples/kiva-agent-maps/kiva-50-500-5.map \
	-a examples/kiva-agent-maps/kiva-50-500-5.map \
	-t examples/kiva-tasks/500/0.task \
	-s PP \
	--capacity 1 \
	--only-update-top \
	--objective total-travel-time \
	--anytime \
	-c 60 \
	--kiva \
	--group-size 5 \
	--destory-method random \
	-o out-quick.txt