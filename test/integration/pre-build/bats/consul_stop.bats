#! /usr/bin/env bats

load test_helper

@test "consul data dir is Empty" {
  run ls -Al /var/lib/consul
  assert_success "total 0"
}

@test "consul Error is not found into Log" {
  run grep "Error|Failed" /var/log/consul.log
  assert_failure
}

@test "consul is stopped" {
  run which systemctl
  if [ $status -eq 0 ]; then
    run systemctl status consul
    run bash -c 'systemctl status consul | grep inactive'
    assert_success
  else
    run service consul status
    assert_equal "${lines[0]}" "consul is stopped"
  fi
}
