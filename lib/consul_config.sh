#!/bin/sh

consul_ssl_cert='/etc/pki/tls/certs/consul.crt'
consul_ssl_key='/etc/pki/tls/private/consul.key'

consul_install_dir='/usr/local/bin'
consul_version='0.6.0'
consul_data_dir='/var/lib/consul'
consul_config_dir='/etc/consul.d'
etc_config_dir='/etc/sysconfig/consul'

#
# function:: os_version
#
os_version() {
  local os_version=6

  if [ -f /etc/redhat-release ]; then
    os_version=$(rpm -qf --queryformat="%{VERSION}" /etc/redhat-release)
  fi

  test ${os_version} -eq $1
  return $?
}

#
# function:: install_consul
#
install_consul() {
  remote_file https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_amd64.zip \
      ${tmp_dir}/consul_${consul_version}_linux_amd64.zip \
      || return $?

  unzip -o -d ${consul_install_dir} ${tmp_dir}/consul_${consul_version}_linux_amd64.zip || return $?
  chmod 755 ${consul_install_dir}/consul || return $?


  directory ${consul_data_dir} root:root 755 || return $?
  directory ${consul_config_dir} root:root 755 || return $?

  cpu_total=`cat /proc/cpuinfo | grep "cpu cores" | head -1 | awk '{print $4}'`
  echo "GOMAXPROCS=${cpu_total}" > ${etc_config_dir}
  chmod 644 ${etc_config_dir}

  if os_version 6; then
    file_copy ${files_dir}/default/consul-init /etc/init.d/consul root:root 755 || return $?
  fi

  if os_version 7; then
    touch /etc/sysconfig/consul-options
    file_copy ${files_dir}/default/consul-options.sh /opt/consul/consul-options.sh root:root 755 || return $?
    file_copy ${files_dir}/default/consul.service /etc/systemd/system/consul.service root:root 644 || return $?
    file_copy ${files_dir}/default/consul.path /etc/systemd/system/consul.path root:root 644 || return $?
    systemctl daemon-reload
  fi

  file_copy ${conf_dir}/consul_default.json ${consul_config_dir}/default.json root:root 644 || return $?

  if [ "${CONSUL_SECRET_KEY}" != "" ] ; then
    package install jq --enablerepo=epel || return $?

    jq ". + {acl_datacenter: .datacenter, acl_default_policy: \"deny\", acl_master_token: \"${CONSUL_SECRET_KEY}\", acl_token: \"anonymous\", encrypt: \"${CONSUL_SECRET_KEY}\"}" ${consul_config_dir}/default.json > ${tmp_dir}/consul_default.json

    file_copy ${tmp_dir}/consul_default.json ${consul_config_dir}/default.json root:root 644 || return $?
  fi

  file_copy ${conf_dir}/consul_watches.json ${consul_config_dir}/watches.json root:root 644 || return $?
}

#
# function:: delete_consul_data
#
delete_consul_data() {
  rm -r -f ${consul_data_dir}/*
}
