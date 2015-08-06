#!/bin/sh

metronome_install_dir='/opt/cloudconductor/bin'
metronome_config_dir='/etc/metronome'

install_metronome() {
  rm -rf ${metronome_install_dir}/metronome
  remote_file https://s3-ap-northeast-1.amazonaws.com/dev.cloudconductor.jp/tools/metronome \
      ${metronome_install_dir}/metronome \
      || return $?

  chmod 755 ${metronome_install_dir}/metronome || return $?

  directory ${metronome_config_dir} root:root 755 || return $?

  values=(`echo $http_proxy | tr -s '/:' ' '`)
  proxy_host=${values[1]}
  proxy_port=${values[2]}

  file_copy ${tmpls_dir}/default/config.yml ${metronome_config_dir}/config.yml root:root 644 || return $?
  sed -i \
      -e "s@__role__@${ROLE}@g" \
      -e "s@__token__@${CONSUL_SECRET_KEY}@g" \
      ${metronome_config_dir}/config.yml \
      || return $?

  if [ -n "${proxy_host}" ]; then
    sed -i \
        -e "s@__proxy-host__@${proxy_host}@g" \
        ${metronome_config_dir}/config.yml \
        || return $?
  else
    sed -i \
        -e "/__proxy-host__/d" \
        ${metronome_config_dir}/config.yml \
        || return $?
  fi

  if [ -n "${proxy_port}" ]; then
    sed -i \
        -e "s@__proxy-port__@${proxy_port}@g" \
        ${metronome_config_dir}/config.yml \
        || return $?
  else
    sed -i \
        -e "/__proxy-port__/d" \
        ${metronome_config_dir}/config.yml \
        || return $?
  fi

  if [ ! -f /etc/init.d/metronome ]; then
    ${metronome_install_dir}/metronome install || return $?
  fi
}
