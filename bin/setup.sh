#!/bin/sh -e
# Copyright 2014-2015 TIS Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

script_root=$(cd $(dirname $0) && pwd)

root_dir=$(cd $(dirname $0)/..;pwd)

files_dir=${root_dir}/files
tmpls_dir=${root_dir}/templates
conf_dir=${root_dir}/conf

tmp_dir=${TMP_DIR}
if [ "${tmp_dir}" == "" ] ; then
  tmp_dir=$(cd ${root_dir}/..;pwd)/tmp
  if [ -d ${tmp_dir} ]; then
    mkdir -p ${tmp_dir}
  fi
fi

lib_dir=${root_dir}/lib

event_handler_dir='/opt/consul/event_handlers'

source ${lib_dir}/functions.sh
source ${lib_dir}/consul_config.sh

# epel repo
package install epel-release || exit $?
sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/epel.repo || exit $?

# iptables disabled
package install iptables || exit $?
service iptables disable
service iptables stop

# create directory for Consul event-handler
directory ${event_handler_dir} root:root 755 || exit $?

# install event-handler
file_copy ${files_dir}/default/event-handler ${event_handler_dir}/event-handler root:root 755 || exit $?

file_copy ${files_dir}/default/action_runner.sh ${event_handler_dir}/action_runner.sh root:root 755 || exit $?
file_copy ${files_dir}/default/patterns.py ${event_handler_dir}/patterns.py root:root 755 || exit $?

# create self-signed certificate for Consul HTTPS API
openssl req -new -newkey rsa:2048 -sha1 -x509 -nodes \
  -set_serial 1 \
  -days 3650 \
  -subj "/C=JP/ST=cloudconductor/L=cloudconductor/CN=`hostname`.consul" \
  -out "${consul_ssl_cert}" \
  -keyout "${consul_ssl_key}" \
|| exit $?

package install libtool || exit $?
package install autoconf || exit $?
package install unzip || exit $?
package install rsync || exit $?
package install make || exit $?
package install gcc || exit $?

# install Consul
install_consul

# setup Consul watches configuration file
file_copy ${conf_dir}/consul_watches.json ${consul_config_dir}/watches.json root:root 644 || exit $?

# delete 70-persistent-net.rules extra lines
if [ -f /etc/udev/rules.d/70-persistent-net.rules ] ; then
  sed -i \
    -e "/^SUBSYSTEM.*/d" \
    -e "/^# PCI device .*/d" \
    /etc/udev/rules.d/70-persistent-net.rules \
  || exit $?
fi

# for pattern
if [ "${PATTERN_URL}" != "" ] ; then
  # checkout pattern
  git_checkout ${PATTERN_URL} /opt/cloudconductor/patterns/${PATTERN_NAME} ${PATTERN_REVISION} || exit $?
  # create symbolic link to pattern logs
  link /opt/cloudconductor/patterns/${PATTERN_NAME}/logs /opt/cloudconductor/logs/${PATTERN_NAME} || exit $?
  # setup services
  for r in `echo ${ROLE} | tr -s ',' ' '`
  do
    echo $r
    if ls /opt/cloudconductor/patterns/${PATTERN_NAME}/services/${r}/*.json ; then
      cp /opt/cloudconductor/patterns/${PATTERN_NAME}/services/${r}/*.json ${consul_config_dir}/
    fi
  done
else
  exit $?
fi

# delete consul data
delete_consul_data

# install jq
package install jq --enablerepo=epel || exit $?

# install hping3
package install hping3 --enablerepo=epel || exit $?
