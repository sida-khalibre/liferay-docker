#!/bin/bash

source /usr/local/bin/_liferay_common.sh

function handle_kill_TERM {
	exec 5<>/dev/tcp/localhost/8005 && echo "SHUTDOWN" >&5

	if [ $? -gt 0 ]; then
		kill -TERM ${START_LIFERAY_PID}
	fi
}

function main {
	echo "[LIFERAY] To SSH into this container, run: \"docker exec -it ${HOSTNAME} /bin/bash\"."
	echo ""

	if [ -d /etc/liferay/mount ]
	then
		LIFERAY_MOUNT_DIR=/etc/liferay/mount
	else
		LIFERAY_MOUNT_DIR=/mnt/liferay
	fi

	export LIFERAY_MOUNT_DIR

	execute_scripts /usr/local/liferay/scripts/pre-configure

	. set_java_version.sh

	. configure_liferay.sh

	execute_scripts /usr/local/liferay/scripts/pre-startup

	start_liferay

	execute_scripts /usr/local/liferay/scripts/post-shutdown

}

function start_liferay {
	set +e

	trap 'handle_kill_TERM' TERM INT

	start_liferay.sh &

	START_LIFERAY_PID=$!

	echo "${START_LIFERAY_PID}" > "${LIFERAY_PID}"

	wait ${START_LIFERAY_PID}

	trap - TERM INT

	wait ${START_LIFERAY_PID}
}

main