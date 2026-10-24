#!/bin/bash
# Known bugs, pinned so an accidental fix shows up as an unexpected pass.

# command_exists returns success only when the command is found
test_command_exists() {
  new_case_sandbox
  local status
  run_coat 'command_exists ls' >/dev/null
  status=$?
  assert_status "$status" 0

  run_coat 'command_exists no_such_command_xyz' >/dev/null
  status=$?
  assert_status "$status" 1
}
