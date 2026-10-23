#!/bin/bash
# Discover and run every test_ function in tests/cases, then print a summary.
set -u

cd "$(dirname "$0")/.." || exit 1
source tests/lib.sh

# load the cases, each one only defines functions
for _case_file in tests/cases/*.sh; do
  # shellcheck source=/dev/null
  source "$_case_file"
done

# tests are shell functions whose names start with test_
mapfile -t TESTS < <(declare -F | awk '{ print $3 }' | grep '^test_' | sort)

# TEST_FILTER lets you run one group, for example TEST_FILTER=paczek make test
if [ -n "${TEST_FILTER:-}" ]; then
  mapfile -t TESTS < <(printf '%s\n' "${TESTS[@]}" | grep "$TEST_FILTER")
fi

if [ "${#TESTS[@]}" -eq 0 ]; then
  echo "no tests found" >&2
  exit 1
fi

for _test in "${TESTS[@]}"; do
  CASE_FAILED=0
  CASE_XFAIL=0
  printf '  %s\n' "${_test#test_}"

  "$_test"

  if [ "$CASE_FAILED" -eq 1 ] && [ "$CASE_XFAIL" -eq 1 ]; then
    printf '    expected failure (known issue)\n'
    XFAIL=$(( XFAIL + 1 ))
  elif [ "$CASE_FAILED" -eq 1 ]; then
    FAIL=$(( FAIL + 1 ))
  elif [ "$CASE_XFAIL" -eq 1 ]; then
    printf '    unexpected pass, the known issue is fixed; remove the xfail\n'
    XPASS=$(( XPASS + 1 ))
  else
    PASS=$(( PASS + 1 ))
  fi

  [ -n "${SB:-}" ] && rm -rf "$SB"
  SB=
done

printf '\n%s passed, %s failed, %s expected failures' "$PASS" "$FAIL" "$XFAIL"
[ "$XPASS" -gt 0 ] && printf ', %s unexpected passes' "$XPASS"
printf '\n'

[ "$FAIL" -eq 0 ] && [ "$XPASS" -eq 0 ]
