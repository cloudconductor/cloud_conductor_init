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

import os
import json
import unittest
import mock
import test_helper

import config


class TestConfig(unittest.TestCase):

    def setup(self):
        self.seq = range(10)

    @mock.patch('config.env')
    @mock.patch('config.file_open')
    def test_load(self, file_open, env):
        env.return_value = None

        dummy_obj = mock.Mock(spec=file)
        file_open.return_value = dummy_obj

        dummy_obj.readlines.return_value = ['ROLE=web,ap', '']

        ret = config.load()

        self.assertIsNotNone(ret)

        self.assertEqual(test_helper.root_path, config.ROOT_DIR)

        self.assertEqual(file_open.call_count, 1)
        self.assertEqual(file_open.call_args, ((config.CONFIG_FILE, 'r'), {}))

        self.assertIsNotNone(ret.data)
        self.assertEqual(ret.data.get('DEFAULT', 'ROLE'), 'web,ap')
        self.assertEqual(ret.get('ROLE'), 'web,ap')

    @mock.patch('config.env')
    @mock.patch('config.file_open')
    def test_get(self, file_open, env):
        env.return_value = None

        dummy_obj = mock.Mock(spec=file)
        file_open.return_value = dummy_obj

        dummy_obj.readlines.return_value = ['ROLE=web,ap', '']

        conf = config.load()

        self.assertIsNotNone(conf)

        self.assertIsNone(conf.get('test_key'))
        self.assertEqual(env.call_args, (('test_key',), {}))

        self.assertEqual(conf.get('ROLE'), 'web,ap')
        self.assertEqual(env.call_args, (('ROLE',), {}))

        env.return_value = 'db'

        self.assertEqual(conf.get('ROLE'), 'db')
        self.assertEqual(env.call_args, (('ROLE',), {}))


if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(TestConfig)
    unittest.TextTestRunner(verbosity=2).run(suite)
