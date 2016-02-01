#!/bin/sh
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

source /opt/cloudconductor/lib/common.sh
source /opt/cloudconductor/lib/run-base.sh

LOG_FILE=${LOG_DIR}/bootstrap_script.log

package() {
  action=$1
  name=$2
  options=$3

  case $action in
    install )
      run bash -c "yum list installed | grep '^${name}\.'"
      info=${output}
      if [ $status -eq 0 ] ; then
        log_info "yum_package[${name}] installed ${name} at ${info[1]}. (skip)"
        return 0
      fi

      run yum install -y ${options} "$name"

      if [ $status -ne 0 ] ; then
        log_error "yum_package[${name}] install failed."
        log_error "$output"
        echo "$output" >&2
        return $status
      fi
      log_info "yum_package[${name}] installed ${name} at ${info[1]}."
    ;;
    erase )
      yum list installed | grep "^$name\." && yum erase -y ${options} "$name"
      status=$?
      if [ $status -ne 0 ] ; then
        log_error "yum_package[${name}] erase failed."
        return $status
      fi
      log_info "yum_package[${name}] erased."
    ;;
  esac
}

directory() {
  path=$1
  owner=$2
  mode=$3

  mkdir -p $path || return $?
  log_info "directory[${path}] created."
  chown $owner $path || return $?
  chmod $mode $path || return $?
}

file_copy() {
  src_path=$1
  to_path=$2
  owner=$3
  mode=$4

  cp $src_path $to_path || return $?
  log_info "file_copy[${to_path}] copied from ${src_path}."
  chown $owner $to_path || return $?
  chmod $mode $to_path || return $?
}

link() {

  ln -s -f $1 $2
  status=$?
  if [ $status -ne 0 ] ; then
    log_error "link[${2}] create failed."
    return $status
  fi
  log_info "link[${2}] created."
}

remote_file() {
  remote_url=$1
  to_path=$2

  run which wget
  if [ $status -eq 0 ] ; then
    run wget -O ${to_path} ${remote_url}
  else
    run which curl
    if [ $status -eq 0 ] ; then
      run curl -L -o ${to_path} ${remote_url}
    fi
  fi

  if [ $status -ne 0 ] ; then
    echo "$output" >&2
  fi

  return $status
}

git_checkout() {
  repository=$1
  path_to_dir=$2
  branch_start_point=$3

  log_info "git cloning repo ${repository} to ${path_to_dir}"

  if [[ "${repository}" != "" ]] && [[ ! -d ${path_to_dir} ]] && [[ ! "$(ls -A ${path_to_dir})"  ]] ; then
    run git clone ${repository} ${path_to_dir}
    if [ $status -ne 0 ]; then
      echo "$output" >&2
      return $status
    fi

    cd ${path_to_dir}
    status=$?
    if [ $status -ne 0 ] ; then
      return $status
    fi

    run git checkout master
    git branch -a | grep deploy && git branch -d deploy

    if git branch -a | grep ${branch_start_point} ; then
      git checkout -f -b deploy origin/${branch_start_point}
      status=$?
      log_info "git [${path_to_dir}] checked out branch ${branch_start_point} onto deploy."
    else
      git checkout -f -b deploy ${branch_start_point}
      status=$?
      log_info "git [${path_to_dir}] checked out branch ${branch_start_point} onto deploy."
    fi
  else
    log_info "git [${path_to_dir}] checkout destination $(basename ${path_to_dir}) already exists or is a non-empty directory"
  fi
}

#
# function:: service_ctl
#
service_ctl() {
  local action=$1
  local svcname=$2

  local os_version=6
  if [ -f /etc/redhat-release ]; then
    os_version=$(rpm -qf --queryformat="%{VERSION}" /etc/redhat-release)
  fi

  case ${os_version} in
    '6' )
      service_ctl_el6 ${action} ${svcname} || return $?
      ;;
    '7')
      service_ctl_el7 ${action} ${svcname} || return $?
      ;;
  esac
}

service_ctl_el6() {
  local action=$1
  local svcname=$2

  run bash -c "service --status-all | grep ${svcname}"
  if [ $status -eq 0 ]; then
    case ${action} in
      'enable' )
        /sbin/chkconfig --add ${svcname} || return $?
        ;;
      'disable' )
        /sbin/chkconfig ${svcname} off
        service ${svcname} stop
        ;;
      *)
        service ${svcname} ${action} || return $?
        ;;
    esac
  fi
}

service_ctl_el7() {
  local action=$1
  local svcname=$2

  run bash -c "systemctl --all | grep \"^${svcname}\""
  if [ "$status" -eq 0 ]; then
    case ${action} in
      'disable' )
        systemctl stop ${svcname}
        systemctl disable ${svcname}
        ;;
      *)
        systemctl ${action} ${svcname} || return $?
        ;;
    esac
  fi
}
