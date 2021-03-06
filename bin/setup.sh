#! /bin/sh -e
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
conf_dir=${root_dir}/conf

tmp_dir=${TMP_DIR}
if [ "${tmp_dir}" == "" ] ; then
  tmp_dir=${root_dir}/tmp
  if [ ! -d ${tmp_dir} ]; then
    mkdir -p ${tmp_dir}
  fi
fi

lib_dir=${root_dir}/lib

source ${lib_dir}/functions.sh
source ${lib_dir}/consul_config.sh
source ${lib_dir}/metronome.sh

# epel repo
package install epel-release || exit $?
sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/epel.repo || exit $?

# iptables disabled
package install iptables || exit $?
service_ctl disable iptables
service_ctl stop iptables

service_ctl disable firewalld || exit $?

package install openssl || exit $?

# create self-signed certificate for Consul HTTPS API
openssl req -new -newkey rsa:2048 -sha1 -x509 -nodes \
  -set_serial 1 \
  -days 3650 \
  -subj "/C=JP/ST=cloudconductor/L=cloudconductor/CN=127-0-0-1.consul" \
  -out "${consul_ssl_cert}" \
  -keyout "${consul_ssl_key}" \
|| exit $?

package install libtool || exit $?
package install autoconf || exit $?
package install unzip || exit $?
package install rsync || exit $?
package install make || exit $?
package install gcc || exit $?
package install jq --enablerepo=epel || exit $?

# install Metronome
install_metronome || exit $?

# install Consul
install_consul || exit $?

# delete 70-persistent-net.rules extra lines
if [ -f /etc/udev/rules.d/70-persistent-net.rules ] ; then
  sed -i \
    -e "/^SUBSYSTEM.*/d" \
    -e "/^# PCI device .*/d" \
    /etc/udev/rules.d/70-persistent-net.rules \
  || exit $?
fi

# prepare all patterns
for pattern_path in /opt/cloudconductor/patterns/*;
do
  # extract pattern name
  name=${pattern_path##*/}
  # create symbolic link to pattern logs
  mkdir -p /opt/cloudconductor/patterns/${name}/logs || exit $?
  link /opt/cloudconductor/patterns/${name}/logs /opt/cloudconductor/logs/${name} || exit $?
  # setup services
  for r in `echo ${ROLE} | tr -s ',' ' '`
  do
    echo $r
    if ls /opt/cloudconductor/patterns/${name}/services/${r}/*.json ; then
      cp /opt/cloudconductor/patterns/${name}/services/${r}/*.json ${consul_config_dir}/
    fi
  done
done

# delete consul data
delete_consul_data || exit $?

# install hping3
package install hping3 --enablerepo=epel || exit $?
