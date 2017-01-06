#!/bin/bash
#
# Define bash functions here
#
# Loaded after environment.sh and aliases.sh
#

# Waits for processes that aren't a child process of this shell
# Pair with:
#   long_running_command & wait # this prints the PID of long_running_command
# to wait for a process in another shell to finish
wait_ext() {
  # Warn if the first PID is not found before we start waiting, since that
  # could mean the provided PID is incorrect
  [[ -e "/proc/$1" ]] || echo "Warning, no PID $1 found."
  while (( "$#" )); do
    while [[ -e "/proc/$1" ]]; do sleep 1; done
    shift
  done
}

# Returns a non-zero exit code if the provided port is not in use
# http://unix.stackexchange.com/q/5277
listening() {
  nc -q 0 localhost "$1" < /dev/null
}

# Busy-waits until the specified ports are accepting requests
wait_port() {
  while (( "$#" )); do
    while ! listening "$1"; do sleep 1; done
    shift
  done
}
