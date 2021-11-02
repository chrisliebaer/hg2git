#!/bin/sh

# may be called from crond
cd /repo

function firstRun() {
	if [[ -z "${HG_URL}" ]]; then
		echo "HG_URL env var is missing"
		exit -1
	fi

	if [[ -z "${GIT_URL}" ]]; then
		echo "GIT_URL env var is missing"
		exit -1
	fi
	
	if [[ -z "${CRON}" ]]; then
		echo "CRON env var is missing"
		exit -1
	fi
	
	echo "#/bin/bash" > config
	echo "export HG_URL=${HG_URL}" >> config
	echo "export GIT_URL=${GIT_URL}" >> config
	echo "export CRON=${CRON}" >> config
	
	echo
	echo "Configuration complete, please check for correctness:"
	echo "*****************"
	cat config
	echo "*****************"
	echo
	
	# setting up cron
	crontab -d
	echo "$CRON flock -n /var/lock/mirror.lock entrypoint.sh update > /proc/1/fd/1 2>/proc/1/fd/2" | crontab -
}

function updateRepo() {
	echo "Update mirror"
	echo "...Fetching updates"
	git -C "mirror" remote update
	echo "...Pushing changes"
	git -C "mirror" push --mirror "$GIT_URL"
	echo
	echo "...done"
}

if [ $1 = "update" ]; then
	echo "Called from crond"
	updateRepo
	exit 0 # exit or else we start a second crond
fi

if [ ! -f "config" ]; then
	echo "First run, configuring and doing full clone"
	firstRun
	
	git clone --mirror "$HG_URL" "mirror"
	git -C "mirror" config fetch.prune true
	
	echo "force update since first run"
	updateRepo
fi

crond -f