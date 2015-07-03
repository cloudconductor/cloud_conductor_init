#!/bin/sh

scheduler_install_dir='/opt/cloudconductor/bin'
scheduler_config_dir='/etc/scheduler'

install_scheduler() {
  rm -rf ${scheduler_install_dir}/scheduler
  remote_file https://s3-ap-northeast-1.amazonaws.com/dev.cloudconductor.jp/tools/scheduler \
      ${scheduler_install_dir}/scheduler \
      || return $?

  chmod 755 ${scheduler_install_dir}/scheduler || return $?

  directory ${scheduler_config_dir} root:root 755 || return $?

  values=(`echo $http_proxy | tr -s '/:' ' '`)
  proxy_host=${values[1]}
  proxy_port=${values[2]}

  file_copy ${tmpls_dir}/default/config.yml ${scheduler_config_dir}/config.yml root:root 644 || return $?
  sed -i \
      -e "s@__role__@${ROLE}@g" \
      -e "s@__token__@${CONSUL_SECRET_KEY}@g" \
      -e "s@__proxy-host__@${proxy_host}@g" \
      -e "s@__proxy-port__@${proxy_port}@g" \
      ${scheduler_config_dir}/config.yml \
      || return $?

  if [ ! -f /etc/init.d/scheduler ]; then
    ${scheduler_install_dir}/scheduler install || return $?
  fi
}
