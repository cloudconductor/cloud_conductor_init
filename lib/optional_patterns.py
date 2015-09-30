#!/usr/bin/env python
# -*- coding: utf-8 -*-
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

import sys
import json
import logging

def consul_kv_get(key):
    import consul
    import config

    conf = config.load()
    c = consul.Consul()
    token_key = conf.token_key()
    index, data = c.kv.get(key, token=token_key)
    obj = json.loads(data['Value'])
    return obj


def read_parameters():
    try:
        ret = consul_kv_get('cloudconductor/parameters')
    except Exception as e:
        logging.warn("%s: %s", type(e), e.message)
        ret = {}
    return ret


def cc_patterns(type=None):
    params = read_parameters()
    patterns = params['cloudconductor']['patterns']
    result = []
    for key, value in patterns.items():
        value['name'] = key
        if type is None:
            result.append(value)

        else:
            if value['type'] == type:
                result.append(value)

    return result

if __name__ == '__main__':
    argvs = sys.argv
    argc = len(argvs)
    print json.dumps(cc_patterns('optional'))
