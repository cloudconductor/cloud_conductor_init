CHANGELOG
=========

## version 1.1.0 (2015/09/30)

  - Support CloudConductor v1.1.
  - Remove the event_handler.sh, modified to control by the Metronome (task order control tool).Therefore, add the requirements(task.yml file etc.) to control from the Metronome.
  - Remove cloud_conductor_util gem from the required gems.
  - Add the requirements for test run in test-kitchen.
  - Replace the implementation of Ruby and Chef into Shell-Script and Python.
  - Support latest consul (version 0.5.2).

## version 1.0.1 (2015/04/16)

  - Fix consul version to be able to run properly.
  - Move event log nodes to under event nodes in consul key-value store to simplify event nodes structure.

## version 1.0.0 (2015/03/27)

  - Support CloudConductor v1.0.
  - Replace serf with consul.
  - Update consul to version 0.5 and use https API.
  - Enable ACL for consul KVS.

## version 0.3.3 (2015/02/25)

  - Fix consul cookbook version to be able to run properly.

## version 0.3.2 (2014/12/24)

  - Support latest serverspec.

## version 0.3.0 (2014/10/31)

  - First release of cloudconductor-init to build base of other patterns.
