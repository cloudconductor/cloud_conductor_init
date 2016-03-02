#!/bin/sh
LANG=en_US.UTF-8

#export PATTERN_NAME="tomcat_pattern"
#export PATTERN_URL="https://github.com/cloudconductor-patterns/tomcat_pattern.git"
#export PATTERN_REVISION=develop
#export ROLE=$1

cp -r -f $(dirname $0)/data /opt/cloudconductor

# for docker-container
touch ./dummy_iptables
cp ./dummy_iptables /etc/init.d/iptables
