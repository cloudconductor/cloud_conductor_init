#!/bin/sh -ex

which git || yum install -y git

cd $(dirname $0)/data

source ./test/scripts/env.sh web

cd /opt/cloudconductor

export ROLE=web
export PATTERNS_JSON='{"tomcat_pattern":{"url":"https://github.com/cloudconductor-patterns/tomcat_pattern.git", "revision":"feature/support-centos7"}}'
export CONSUL_SECRET_KEY=HLsQyVZOuq6qPPzA89KEmw==

echo "ROLE=${ROLE}" >> /opt/cloudconductor/config
if [ "${CONSUL_SECRET_KEY}" != "" ] ; then
  echo "CONSUL_SECRET_KEY=${CONSUL_SECRET_KEY}" >> /opt/cloudconductor/config
fi

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

bash -ex ./bin/init.sh
