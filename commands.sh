#!/bin/bash
#
# Commands to execute in interactive terminals
#
# Executed last
# Not included in non-interactive terminals, like cron
#

screencount=$(($(screen -ls | wc -l)-3))
if [ $screencount -gt 0 ]; then
  echo "There are $screencount open screen sessions"
fi
