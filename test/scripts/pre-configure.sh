#!/bin/sh -ex

which git || yum install -y git

cd $(dirname $0)/data

source ./test/scripts/env.sh web

cd /opt/cloudconductor

export ROLE=web
export PATTERNS_JSON='{"tomcat_pattern":{"url":"https://github.com/cloudconductor-patterns/tomcat_pattern.git", "revision":"feature/support-centos7"}}'
#export CONSUL_SECRET_KEY=HLsQyVZOuq6qPPzA89KEmw==

echo "ROLE=${ROLE}" >> /opt/cloudconductor/config
if [ "${CONSUL_SECRET_KEY}" != "" ] ; then
  echo "CONSUL_SECRET_KEY=${CONSUL_SECRET_KEY}" >> /opt/cloudconductor/config
fi

git clone https://github.com/cloudconductor-patterns/tomcat_pattern.git /opt/cloudconductor/patterns/tomcat_pattern
cd /opt/cloudconductor/patterns/tomcat_pattern
git checkout feature/support-centos7

cd /opt/cloudconductor
echo BOOTSTRAP_EXPECT=1 >> /opt/cloudconductor/config

os_version=$(rpm -qf --queryformat="%{VERSION}" /etc/redhat-release)

# for centos6 on docker
if [ ${os_version} -eq 6 ]; then
  yum install -y epel-release
  yum install -y gecode-devel
  export USE_SYSTEM_GECODE=1
else
  bash -ex test/bin/chef-ruby-env.sh
fi

yum install -y python-setuptools

if [ ${os_version} -eq 7 ]; then
  yum update -y
fi

bash -ex ./bin/init.sh

source /opt/cloudconductor/lib/common.sh

if [ -f ${CHEF_ENV_FILE} ]; then
  source ${CHEF_ENV_FILE}
fi

export no_proxy=localhost,127.0.0.1

which systemctl && systemctl start consul || service consul start
sleep 10

output="$(bash -ex ./bin/configure.sh ${CONSUL_SECRET_KEY})"
status=$?

if [ $status -ne 0 ] ; then
  echo $output
  exit $status
fi
