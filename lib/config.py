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

import ConfigParser
import os

file_dir = os.path.dirname(__file__)
ROOT_DIR = os.path.abspath(os.path.join(file_dir, '..'))

LOG_DIR = os.path.join(ROOT_DIR, 'logs')
PATTERNS_DIR = os.path.join(ROOT_DIR, 'patterns')
CONFIG_FILE = os.path.join(ROOT_DIR, 'config')

if not os.path.exists(LOG_DIR):
    os.mkdir(LOG_DIR)

LOG_FILE = os.path.join(LOG_DIR, 'bootstrap.log')


def env(name):
    return os.environ.get(name)


def load(path=None):
    return Config(path)


def file_open(path, mode):
    return open(path, mode)


class Config:

    def __init__(self, path=None):
        self.data = None
        if path is None:
            path = CONFIG_FILE
        self.data = self.load(path)

    def load(self, path):
        fp = file_open(path, 'r')
        lines = fp.readlines()
        fp.close

        tmp = os.tmpfile()
        tmp.writelines(["[DEFAULT]", os.linesep])
        tmp.writelines(lines)
        tmp.seek(0)
        conf = ConfigParser.SafeConfigParser()
        conf.readfp(tmp)
        tmp.close()

        return conf

    def get(self, key):
        ret = env(key)
        if ret is None:
            if self.data is not None and self.data.has_option('DEFAULT', key):
                ret = self.data.get('DEFAULT', key)

        return ret

    def roles(self):
        ret = self.get('ROLE')
        return ret.split(',')

    def token_key(self):
        return self.get('CONSUL_SECRET_KEY')
