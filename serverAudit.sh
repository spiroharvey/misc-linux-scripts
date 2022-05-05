#!/bin/bash

# RHEL Linux Server Audit Tool, v1
# by Spiro Harvey <spiro.harvey@protonmail.com>, Nov 2021
# meminfo functions taken from https://github.com/spiroharvey/random-scripts



if [ $(id -u) -ne 0 ]; then
	printf "This script is more useful when run as root.\n"
	exit 1
fi


function usage() {
	printf "Usage: %s <hostname> [>outputfile] \n",$0
}

# function name starts with underscore so it's not
# confused with existing indent program
function _indent_out() {
	sed 's/^/\t/'
}

# grab a value from meminfo
function extract_value() {
	grep ^${1}: /proc/meminfo | awk '{print $2}'
}

# convert the value from kb to gb
function calc_gb() {
	echo $1 | awk '{printf "%.3f", $1/1024/1024}'
}

date_stamp=$(date)

printf "\n%*s%s\n" "$(( $((78 - ${#HOSTNAME})) / 2 ))" " " $(uname -n | tr [:lower:] [:upper:])
printf "%*s$date_stamp\n" "$((78 - ${#date_stamp}))" " "

printf "\n============================== Host Information ==============================\n\n"
printf "Hostname : $(hostname -s)\n"
printf "FQDN     : $(uname -n)\n"
printf "Kernel   : $(uname -r)\n"
if [ -f /etc/redhat-release ]; then
	printf "RH Rel   : $(cat /etc/redhat-release)"
fi
printf "\n"
printf "uptime   : $(uptime)\n"
printf "CPUs     : $(grep ^processor /proc/cpuinfo | wc -l)\n"
printf "\n"
memTotal=$(extract_value MemTotal)
memFree=$(extract_value MemFree)
memBuffers=$(extract_value Buffers)
memCache=$(extract_value Cached)
memFreeActual=$(($memFree + $memBuffers + $memCache))

printf "Mem Total: %8.3f GB\n" $(calc_gb $memTotal)
printf "Mem Free : %8.3f GB\n" $(calc_gb $memFreeActual)

if [ -f /etc/os-release ]; then
	printf "\n### /etc/os-release:\n"
	cat /etc/os-release | _indent_out
fi

printf "\n================================ SELinux =====================================\n\n"

printf "\n### sestatus:\n"
sestatus | _indent_out

printf "\n### /etc/selinux/config:\n"
grep -v '^\s*$\|^\s*\#' /etc/selinux/config | _indent_out

printf "\n============================== File Systems ==================================\n\n"

printf "\n###  /etc/fstab:\n"
cat /etc/fstab | grep -v ^# | _indent_out

printf "\n###  Local Mounts:\n"
df -hTlx tmpfs -x devtmpfs | _indent_out

printf "\n###  NFS Mounts:\n"
df -hTt nfs | _indent_out


printf "\n=========================== Network Information ==============================\n\n"

printf "\n###  Network Interfaces:\n"
ip a | _indent_out

printf "\n###  /etc/resolv.conf:\n"
cat /etc/resolv.conf | _indent_out

printf "\n###  /etc/hosts:\n"
cat /etc/hosts | _indent_out


printf "\n###  Open TCP ports:\n"
netstat -ntlp | _indent_out


printf "\n============================= Firewall (iptables) ============================\n\n"
iptables -nvL | _indent_out

printf "\n### /etc/sysconfig/iptables-config:\n"
grep -v '^\s*$\|^\s*\#' /etc/sysconfig/iptables-config | _indent_out


printf "\n### /etc/sysconfig/ip6tables-config:\n"
grep -v '^\s*$\|^\s*\#' /etc/sysconfig/ip6tables-config | _indent_out





which firewall-cmd >/dev/null 2>/dev/null
if [ $? == 0 ]; then
	printf "\n================================== FirewallD =================================\n\n"
	printf "\n### firewall-cmd --list-all-zones\n"
	firewall-cmd --list-all-zones | _indent_out

	printf "\n### firewall-cmd --list-all-zones --permanent\n"
	firewall-cmd --list-all-zones --permanent | _indent_out
fi


printf "\n============================== Running Services ==============================\n\n"


which systemctl >/dev/null 2>/dev/null
if [ $? == 0 ]; then
	printf "\n###  systemd services:\n"
	systemctl list-unit-files --type=service | grep enabled | _indent_out
fi


which chkconfig >/dev/null 2>/dev/null
if [ $? == 0 ]; then
	printf "\n###  chkconfig services:\n"
	chkconfig --list 2>/dev/null | grep -v 3:off | awk '{print $1}' | _indent_out
fi

if [ -f /etc/rc.d/rc.local ]; then
	printf "\n### /etc/rc.d/rc.local\n"
	cat /etc/rc.d/rc.local | _indent_out
fi


printf "\n============================== Crontabs ======================================\n\n"
ls -ld /var/spool/cron/* | _indent_out
printf "\n"

for f in /var/spool/cron/*; do
	printf "\n### %s:\n" $f 
	cat $f | _indent_out
done
printf "\n"

printf "\n============================== SSHD Config ===================================\n\n"

grep -v '^\s*$\|^\s*\#' /etc/ssh/sshd_config | _indent_out



printf "\n============================== NSSwitch ======================================\n\n"
cat /etc/nsswitch.conf | _indent_out


printf "\n========================= Installed Packages =================================\n\n"
yum list installed 2>/dev/null | _indent_out

