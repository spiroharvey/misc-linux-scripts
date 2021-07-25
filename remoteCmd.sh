#!/bin/bash
#
# by Spiro


if [ -z "$2" ]; then
	printf "Usage: $0 <FILE> <COMMAND>\n"
	printf "Iterates over a list of hosts sending them commands.\n\n"
	printf "  FILE      plain text file containing list of hosts\n"
	printf "  COMMAND   ssh command to send to each remote host\n\n"
	printf "eg; $0 dev-hosts.txt \"ls -l\"\n"
	exit 1
fi


hostFile="$1"
remoteCommand="${2}"


function remoteCommand() {
	ssh -q $1 "$2"
}

while read hostLine; do
	# skip any hosts that are commented out
	[[ $hostLine =~ ^\# ]] && continue
	[[ $hostLine =~ ^\; ]] && continue
	[[ $hostLine == "" ]] && continue
	host=$(echo $hostLine | cut -d' ' -f1)

	printf "[1;33m%-20s[0m" $host
	# ping if host is alive
	ping -qc 1 $host >/dev/null 2>/dev/null

	if [ $? -eq 0 ]; then
		# host is up
		printf "[1;32mUP[0m "
		# check if SSH port is open (to ID linux hosts)
		nc -zw3 $host 22
		if [ $? -eq 0 ]; then
			# port 22 open
			printf "[1;32mSSH-OK[0m\n"
			remoteCommand $host "$remoteCommand"
		else
			# can't ssh, don't try anything else
			printf "[1;31m%NO-SSH[0m\n"
		fi
	else
		# host is down
		printf "[1;31mDN[0m\n"
	fi
done < $hostFile


