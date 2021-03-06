#!/usr/bin/env bats

load test_helper

setup() {
  init_debian
  stub_debian
}

teardown() {
  unstub_debian
  rm -fr "${TMP}"/*
}

@test "start td-agent with backward-compatibile configuration (debian)" {
  cat <<EOS > "${TMP}/etc/default/td-agent"
NAME="custom_name"
EOS

  stub_path /sbin/start-stop-daemon "true" \
                                    "echo start-stop-daemon; for arg; do echo \"  \$arg\"; done"
  stub log_end_msg "0 : true"

  run_service start
  assert_output <<EOS
Warning: Declaring \$NAME in ${TMP}/etc/default/td-agent for customizing \$PIDFILE has been deprecated. Use \$TD_AGENT_PID_FILE instead.
start-stop-daemon
  --start
  --quiet
  --pidfile
  ${TMP}/var/run/custom_name/custom_name.pid
  --exec
  ${TMP}/opt/td-agent/embedded/bin/ruby
  -c
  td-agent
  --group
  td-agent
  --
  ${TMP}/usr/sbin/td-agent
  --daemon
  ${TMP}/var/run/custom_name/custom_name.pid
  --log
  ${TMP}/var/log/td-agent/td-agent.log
  --use-v1-config
EOS
  assert_success

  unstub_path /sbin/start-stop-daemon
  unstub log_end_msg
}
