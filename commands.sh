#!/bin/bash
#
# Commands to execute in interactive terminals
#
# Executed last
# Not included in non-interactive terminals, like cron
#

if command -v screen > /dev/null; then
  screens=$(screen -ls | grep '^'$'\t' | awk '{ print $1 }' | sed 's/[0-9]*\.//' | sort)
  if [[ -n "$screens" ]]; then
    echo "Open screen sessions: $(echo "$screens" | wc -w)"
    echo " " $screens # intentionally unquoted to put everything on one line
  fi
fi
