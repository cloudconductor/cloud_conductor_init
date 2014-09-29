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

CONDUCTOR_DIR="/opt/cloudconductor"
CONFIG_DIR="${CONDUCTOR_DIR}/etc"
TMP_DIR="${CONDUCTOR_DIR}/tmp"
LOG_DIR="${TMP_DIR}/logs"
FILE_CACHE_DIR="${TMP_DIR}/cache"

mkdir -p ${TMP_DIR}
mkdir -p ${LOG_DIR}
mkdir -p ${FILE_CACHE_DIR}

cd ${CONFIG_DIR}
berks vendor ${TMP_DIR}/cookbooks
cd ${CONDUCTOR_DIR}
chef-solo -j ${CONFIG_DIR}/node_setup.json -c ${CONFIG_DIR}/solo.rb

SERF_USER_EVENT="setup" /opt/serf/event_handlers/event-handler
