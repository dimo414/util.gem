#!/usr/bin/env bats
#
# Unit tests for util.gem
#
# Note that some of the behavior in this gem depends on being connected to a TTY, which is difficult
# to test under non-TTY conditions such as continuous integration. For now such tests are skipped,
# however it may be possible to fake the TTY connection well enough. See the options in
# https://stackoverflow.com/q/1401002/113632 for more.

source $BATS_TEST_DIRNAME/../functions.sh

pg::log() { echo "PGEM_LOG" "$@"; }

expect_eq() {
  (( $# == 2 )) || { echo "Invalid inputs $*"; return 127; }
  if [[ "$1" != "$2" ]]; then
    echo "Actual:   '$1'"
    echo "Expected: '$2'"
    return 1
  fi
}

@test "if_stdin handles simple commands" {
  [[ -t 0 ]] || skip # see comment above
  foo() {
    if_stdin "echo stdin" "echo nostdin" "$@"
  }

  expect_eq "$(: | foo)" "stdin"
  expect_eq "$(foo | cat)" "nostdin"
  expect_eq "$(foo < /dev/null)" "stdin"
  expect_eq "$(foo > /dev/stdout)" "nostdin"
  expect_eq "$(foo)" "nostdin"

  expect_eq "$(: | foo bar)" "stdin bar"
  expect_eq "$(foo bar)" "nostdin bar"
}

@test "if_stdin handles compound commands" {
  [[ -t 0 ]] || skip # see comment above
  echo_cruft() {
    echo "$@"
    echo unrelated noise
  }
  foo() {
    if_stdin "echo_cruft stdin | grep stdin" "echo_cruft nostdin | grep stdin" "$@"
  }

  expect_eq "$(: | foo)" "stdin"
  expect_eq "$(foo)" "nostdin"

  expect_eq "$(: | foo -v)" "unrelated noise"
  expect_eq "$(foo -v)" "unrelated noise"
}

@test "if_stdin doesn't eval arguments" {
  [[ -t 0 ]] || skip # see comment above
  foo() {
    if_stdin "echo stdin" "echo nostdin" "$@"
  }

  expect_eq "$(: | foo '| grep foo')" "stdin | grep foo"
  expect_eq "$(foo '| grep foo')" "nostdin | grep foo"
}

@test "quiet_success" {
  foo() {
    echo "foo"
    echo "bar" >&2
    return ${1:-127}
  }

  run quiet_success foo 0
  expect_eq "$output" ""
  (( $status == 0 ))

  run quiet_success foo 15
  expect_eq "${lines[0]}" "foo"
  expect_eq "${lines[1]}" "bar"
  (( ${#lines[@]} == 2 ))
  (( $status == 15 ))
}

@test "emailme" {
  local tmp=$(mktemp)
  sendmail() { cat - > "$tmp"; }
  task() { echo foo; return 1; }

  EMAIL='foo@bar.com'

  run emailme task
  expect_eq "$(grep 'To:' "$tmp")" "To: foo@bar.com"
  expect_eq "$(grep 'Subject:' "$tmp")" "Subject: Finished running task"
  expect_eq "$(grep 'Status:' "$tmp")" "Status: 1"
  (( status == 0 ))
}
