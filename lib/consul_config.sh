#!/bin/sh

consul_ssl_cert='/etc/pki/tls/certs/consul.crt'
consul_ssl_key='/etc/pki/tls/private/consul.key'

consul_install_dir='/usr/local/bin'
consul_version='consul_0.6.0_linux_amd64'
consul_data_dir='/var/lib/consul'
consul_config_dir='/etc/consul.d'
etc_config_dir='/etc/sysconfig/consul'

install_consul() {
  remote_file https://releases.hashicorp.com/consul/0.6.0/${consul_version}.zip \
      ${tmp_dir}/${consul_version}.zip \
      || return $?

  unzip -o -d ${consul_install_dir} ${tmp_dir}/${consul_version}.zip || return $?
  chmod 755 ${consul_install_dir}/consul || return $?


  directory ${consul_data_dir} root:root 755 || return $?
  directory ${consul_config_dir} root:root 755 || return $?

  cpu_total=`cat /proc/cpuinfo | grep "cpu cores" | head -1 | awk '{print $4}'`
  echo "GOMAXPROCS=${cpu_total}" > ${etc_config_dir}
  chmod 644 ${etc_config_dir}

  file_copy ${files_dir}/default/consul-init /etc/init.d/consul root:root 755 || return $?

  file_copy ${conf_dir}/consul_default.json ${consul_config_dir}/default.json root:root 644 || return $?

  if [ "${CONSUL_SECRET_KEY}" != "" ] ; then
    package install jq --enablerepo=epel || return $?

    jq ". + {acl_datacenter: .datacenter, acl_default_policy: \"deny\", acl_master_token: \"${CONSUL_SECRET_KEY}\", acl_token: \"anonymous\", encrypt: \"${CONSUL_SECRET_KEY}\"}" ${consul_config_dir}/default.json > ${tmp_dir}/consul_default.json

    file_copy ${tmp_dir}/consul_default.json ${consul_config_dir}/default.json root:root 644 || return $?
  fi

  file_copy ${conf_dir}/consul_watches.json ${consul_config_dir}/watches.json root:root 644 || return $?
}

delete_consul_data() {
  rm -r -f ${consul_data_dir}/*
}
