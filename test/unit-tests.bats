#!/usr/bin/env bats

source $BATS_TEST_DIRNAME/../functions.sh

pgem_log() { echo "PGEM_LOG" "$@"; }

@test "if_stdin handles simple commands" {
  foo() {
    if_stdin "echo stdin" "echo nostdin" "$@"
  }

  [[ "$(: | foo)" == "stdin" ]]
  [[ "$(foo)" == "nostdin" ]]

  [[ "$(: | foo bar)" == "stdin bar" ]]
  [[ "$(foo bar)" == "nostdin bar" ]]
}

@test "if_stdin handles compound commands" {
  echo_cruft() {
    echo "$@"
    echo unrelated noise
  }
  foo() {
    if_stdin "echo_cruft stdin | grep stdin" "echo_cruft nostdin | grep stdin" "$@"
  }

  [[ "$(: | foo)" == "stdin" ]]
  [[ "$(foo)" == "nostdin" ]]

  [[ "$(: | foo -v)" == "unrelated noise" ]]
  [[ "$(foo -v)" == "unrelated noise" ]]
}

@test "if_stdin doesn't eval arguments" {
  foo() {
    if_stdin "echo stdin" "echo nostdin" "$@"
  }

  [[ "$(: | foo '| grep foo')" == "stdin | grep foo" ]]
  [[ "$(foo '| grep foo')" == "nostdin | grep foo" ]]
}

@test "quiet_success" {
  foo() {
    echo "foo"
    echo "bar" >&2
    return $1
  }

  run quiet_success foo 0
  (( $status == 0 ))
  [[ "$output" == "" ]]

  run quiet_success foo 15
  (( $status == 15 ))
  (( ${#lines[@]} == 2 ))
  [[ "${lines[0]}" == "foo" ]]
  [[ "${lines[1]}" == "bar" ]]
}

@test "emailme" {
  local tmp=$(mktemp)
  sendmail() { cat - > "$tmp"; }
  task() { echo foo; return 1; }

  EMAIL='foo@bar.com'

  run emailme task
  (( status == 0 ))
  [[ "$(grep 'To:' "$tmp")" == "To: foo@bar.com" ]]
  [[ "$(grep 'Subject:' "$tmp")" == "Subject: Finished running task" ]]
  [[ "$(grep 'Status:' "$tmp")" == "Status: 1" ]]
}
