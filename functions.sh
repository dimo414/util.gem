#!/bin/bash
#
# Define bash functions here
#
# Loaded after environment.sh and aliases.sh
#

#
# Shell Functions
#

# Takes two (generally sibling) commands to execute based on whether or not
# stdin is being written to. $1 is executed if input is being piped in,
# $2 is executed otherwise.
#
# Generally speaking it's simpler and cleaner to just write a function that
# checks [[ -t 0 ]] or [[ -p /dev/stdin ]] (like this function), however this
# function enables defining concise aliases that react to stdin being piped.
# See the clipboard examples in aliases.sh - those three lines would take up
# almost 20 if defined in their own (near-identical) functions.
#
# Note: be careful if calling this function from scripts or other functions,
# as non-TTY environments may *look* like there's a stdin when there isn't.
# Using this function only in aliases avoids the issue since aliases are
# (by default) not defined in non-interactive environments.
# See https://stackoverflow.com/a/30520299/113632
if_stdin() {
  local has_stdin="${1:?Must specify a command for stdin}"
  shift
  local no_stdin="${1:?Must specify a command for no stdin}"
  shift
  # Need to use eval to support things like > redirection
  # Which in turn means we need to escape any remaining args
  local args
  if (( $# )); then
    args=$(printf '%q ' "$@")
  fi
  if ! [[ -t 0 ]]; then # maybe `|| [[ -p /dev/stdin ]]` ?
    eval "$has_stdin $args"
  else
    eval "$no_stdin $args"
  fi
}

# Buffers all output of the passed command, and only prints on error
# Uses eval to support pipes and multiple commands, but defining a
# wrapper function is generally recommended.
# http://unix.stackexchange.com/a/41388/19157
# TODO try http://joeyh.name/code/moreutils/ on Cygwin and just wrap chronic
# if it's on the PATH.
quiet_success() {
  local output
  output=$( eval "$@" 2>&1 )
  local ret=$?
  if (( ret != 0 )); then
    echo "$output"
    return $ret
  fi
}

# Uses https://github.com/junegunn/fzf "fuzzy find" to support easily cd-ing
# to commonly used directories. Add paths to GOTO_PATHS or GOTO_DIRS to
# include them in the search.
# Arguments to this function seed the fuzzy find; if the arguments match
# exactly one path skips the find UI and jumps straight to the directory.
goto() {
  local fzf_flags=()
  # if an argument is passed and does not contain a / search only against the
  # final directory.
  # Maybe this should be the default behavior, even with no arguments?
  # That would require users to say `goto /` in order to search the full path
  # which would be somewhat surprising.
  if (( $# > 0 )) && [[ "$*" != *'/'* ]]; then
    fzf_flags=('--delimiter=/' '--nth=-1')
  fi

  local path
  path=$(
    { (( ${#GOTO_PATHS[@]} > 0 )) && find -L "${GOTO_PATHS[@]}" \
        -mindepth 1 -maxdepth 1 -not -path '*/\.*' -type d -print0
      (( ${#GOTO_DIRS[@]} > 0 )) && printf '%s\0' "${GOTO_DIRS[@]}"
    } | sort -z \
      | fzf --tiebreak=end --select-1 --exit-0 --read0 "${fzf_flags[@]}" \
        --query="$*"
  ) || return
  # https://github.com/koalaman/shellcheck/issues/613
  # shellcheck disable=SC2164
  cd "$path"
}

# Adds ANSI colors to matched terms, similar to grep --color but without
# filtering unmatched lines. Example:
#   noisy_command | highlight ERROR INFO
#
# Each argument is passed into sed as a matching pattern and matches are
# colored. Multiple arguments will use separate colors.
#
# Inspired by https://stackoverflow.com/a/25357856
highlight() {
  # color cycles from 0-5, (shifted 31-36), i.e. r,g,y,b,m,c
  local color=0 patterns=()
  for term in "$@"; do
    patterns+=("$(printf 's|%s|\e[%sm\\0\e[0m|g' "${term//|/\\|}" "$(( color+31 ))")")
    color=$(( (color+1) % 6 ))
  done
  sed -f <(printf '%s\n' "${patterns[@]}")
}

if command -v screen > /dev/null; then
# Prints the currently open screen sesions
screens() {
  screen -ls | sed -n 's/^\t[0-9]*\.\([^\t]*\).*/\1/p' | sort
}

# Configures screen with logging enabled and written to a dedicated file
_screen_logging() {
  local session="${1:?Must specify a screen session name.}"
  local logfile="/tmp/screen.${session}.log"
  shift
  # http://serverfault.com/a/248387
  # https://stackoverflow.com/a/50651839
  # https://unix.stackexchange.com/q/373115
  screen -S "$session" -h 10000 -L -Logfile "$logfile" "$@"
  echo "Logfile at $logfile"
}

# Opens a screen session with the given name, either creating a new session or
# attaching to one that already exists. Also enables logging for the session.
screenopen() {
  local session="${1:?Must specify a screen session name.}"
  _screen_logging "$session" -d -R
}

# Creates a screen session (if it doesn't already exist), and then writes all
# arguments to the screen's command buffer. To execute the commands, append
# with `\n`. To execute and exit upon success append with `&& exit\n`.
#
# Note that arguments are written to the command-buffer as-is, so special
# characters (shell syntax like &&, as well as whitespace) is not escaped.
# To escape variables use ${...@Q} expansion, which will write the contents
# to the buffer properly escaped.
screencmd() {
  local session="${1:?Must specify a screen session name.}"
  shift
  if (( $# == 0 )); then
    pg::err "Must provide a command to run"
    return 1
  fi
  # https://stackoverflow.com/a/28724362
  screen -S "$session" -X select . &>/dev/null || \
    _screen_logging "$session" -d -m
  sleep 1 # let screen startup, not sure if this is necessary
  screen -S "$session" -X stuff "$*"
  printf "Wrote '%s' to '%s'\nTo open run:\n  screenopen '%s'\nthen <Ctrl>+a d to detatch.\n" \
    "$*" "$session" "$session"
}
fi # if screen is installed

# Grep ps command
# Inspiration: http://www.commandlinefu.com/commands/view/977/
# Alternately: http://code.google.com/p/psgrep/
# TODO how is this better than pgrep?
# https://github.com/koalaman/shellcheck/wiki/SC2009
psgrep() {
  local psargs grepargs
  if [[ -z "$2" ]]
  then
    psargs="aux"
    greparg="$1"
  else
    psargs="$1"
    greparg="$2"
  fi
  # shellcheck disable=SC2001
  greparg=$(echo "$greparg" | sed 's|\(.\)$|[\1]|')
  # shellcheck disable=SC2086
  ps $psargs | head -n 1
  # shellcheck disable=SC2009,SC2086
  ps $psargs | grep -i "$greparg"
}

# Send an email when the process passed as an argument terminates
emailme() {
  local usage=(
    'emailme cmd cmdargs...'
    'EMAIL=user@example.com emailme cmd cmdargs...')
  if [[ -z "$1" ]]; then
    printf 'Usage: %s\n' "${usage[@]}" >&2
    return 0
  fi

  if [[ -z "$EMAIL" ]]; then
    echo 'No EMAIL value found' >&2
    printf 'Usage: %s\n' "${usage[@]}" >&2
    return 1
  fi

  local cmd=$1
  shift
  time $cmd "$@"

  printf "From: %s\nTo: %s\nSubject: Finished running %s\n\nRan: %s\n\nStatus: %s\n" \
    "$EMAIL" "$EMAIL" "$cmd" "${cmd} $*" "$?" \
    | sendmail -t
  pg::log "Emailed $EMAIL"
}

# Extracts archives of different types
# http://www.shell-fu.org/lister.php?id=375
extract() {
  if [[ -f "$1" ]] ; then
    case "$1" in
      *.tar.bz2)   tar xvjf "$1"    ;;
      *.tar.gz)    tar xvzf "$1"    ;;
      *.bz2)       bunzip2 "$1"     ;;
      *.rar)       unrar x "$1"     ;;
      *.gz)        gunzip "$1"      ;;
      *.tar)       tar xvf "$1"     ;;
      *.tbz2)      tar xvjf "$1"    ;;
      *.tgz)       tar xvzf "$1"    ;;
      *.zip|*.jar) unzip "$1"       ;;
      *.Z)         uncompress "$1"  ;;
      *.7z)        7z x "$1"        ;;
      *)
        echo "'$1' cannot be extracted via extract"
        return 2
        ;;
    esac
  else
    echo "'$1' is not a valid file"
    return 1
  fi
}

# Basic implementation of exponential backoff; invokes the given command
# until it succeeds. All stderr is preserved, but stdout from failed invocations
# is discarded
backoff() {
  if (( $# < 3 )); then
    pg::err "Usage: backoff MIN_DELAY_SEC MAX_DELAY_SEC CMD [ARGS...]"
    return 2
  fi

  local min=$1
  local max=$2
  if (( min < 1 )) 2>/dev/null || (( max <= min)) 2>/dev/null; then
    pg::err "Invalid backoff range, MIN must be positive and MAX > MIN"
    return 1
  fi
  shift; shift

  local output delay="$min"
  output=$(mktemp --suffix=.txt) || return
  while true; do
    if "$@" > "$output"; then
      cat "$output"
      rm -f "$output"
      return
    fi
    sleep "${delay}s" || return
    # increase delay by 1-10x
    delay=$(( delay * (RANDOM % 10 + 1) ))
    # cap delay at max, including overflows
    delay=$(( delay > max || delay <= 0 ? max : delay ))
  done
}

# Waits for processes that aren't a child process of this shell
# Pair with:
#   long_running_command & wait # this prints the PID of long_running_command
# to wait for a process in another shell to finish
wait_ext() {
  # Warn if the first PID is not found before we start waiting, since that
  # could mean the provided PID is incorrect
  [[ -e "/proc/$1" ]] || echo "Warning, no PID $1 found." >&2
  while (( "$#" )); do
    while [[ -e "/proc/$1" ]]; do sleep 1; done
    shift
  done
}

# Returns a non-zero exit code if the provided port is not in use
listening() {
  nc -z localhost "$1"
}

# Busy-waits until the specified ports are accepting requests
wait_port() {
  while (( "$#" )); do
    while ! listening "$1"; do sleep 1; done
    shift
  done
}

# Launches a Bash shell without any .rc customizations
# Useful for testing behavior that might be impacted by your environment.
# https://stackoverflow.com/a/41554230/113632
#
# This function will pass additional arguments to Bash, e.g. `-c 'foo'` will
# invoke foo in a pristine shell non-interactively.
pristine_bash() {
  # Persist a few core environment variables, if they're set
  local env_vars=(
    ${DISPLAY:+"DISPLAY=${DISPLAY}"}
    ${HOME:+"HOME=${HOME}"}
    ${LANG:+"LANG=${LANG}"}
    ${PATH:+"PATH=${PATH}"}
    ${TERM:+"TERM=${TERM}"}
    ${USER:+"USER=${USER}"}
  )
  env -i "${env_vars[@]}" bash --noprofile --norc "$@"
}

#
# Git Functions
#

# Syncs a fork with the upstream repo
# https://help.github.com/articles/syncing-a-fork/
gitsyncfork() {
  git fetch upstream &&
  git checkout master &&
  git merge upstream/master &&
  echo "Ready to push with 'git push'"
}

# Rebase all commits not found in the upstream master (i.e. in a PR)
# generally in order to squash them all into one commit.
# https://stackoverflow.com/a/15055649/113632
gitsquash() {
  if ! git config remote.upstream.url > /dev/null; then
    pg::err "'upstream' remote not set; use 'git remote add upstream REPO_LOCATION'"
    return 1
  fi
  git fetch upstream &&
    git rebase -i upstream/master &&
    echo "Push rebased changes with 'git push -f'"
}

#
# Dev Functions
#

# Creates a Java pseudo-REPL for quick prototyping.
# Launches an editor with a new Java file, then compiles and runs the file
# after the editor exits.
# Re-running in the same shell session opens the same file.
java_demo() {
  local dir="${TMP:-/tmp}"
  local class="Demo$$"
  local path="${dir}/${class}.java"
  if ! [[ -f "$path" ]] ; then
    cat << EOF > "$path"
import java.util.*;

public class $class {
  public static void main(String[] args) {
    
  }
}
EOF
  fi
  # cd to /tmp to support Cygwin - Java doesn't like absolute Cygwin paths
  (cd "$dir" &&
   vi ${class}.java &&
   echo "javac $path" >&2 && javac "${class}.java" &&
   echo "java -cp $dir $class" >&2   && java -cp . "$class"
  )
}
