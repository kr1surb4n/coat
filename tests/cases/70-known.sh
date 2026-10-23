#!/bin/bash
# Known bugs, pinned so an accidental fix shows up as an unexpected pass.

# ISS-01: command_exists uses `return type ...`, which returns 2 every time
test_command_exists_is_broken() {
  new_case_sandbox
  xfail "ISS-01: command_exists always returns 2"
  local status
  run_coat 'command_exists ls' >/dev/null
  status=$?

  assert_status "$status" 0
}
