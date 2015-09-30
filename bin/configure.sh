#!/bin/sh
# Copyright 2014 TIS Inc.
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
source /opt/cloudconductor/lib/python-env.sh

CONFIG_DIR="${ROOT_DIR}/etc"
LOG_FILE="${LOG_DIR}/bootstrap.log"

log_info "update consul ACL for service synchronization."
enable_service_acl $1

log_info "execute register_server.py."
python_exec ${ROOT_DIR}/lib/register_server.py
if [ $? -ne 0 ]; then
  log_error "register_server.py has finished abnormally."
  exit -1
fi
log_info "register_server.py has finished successfully."
