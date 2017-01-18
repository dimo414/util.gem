#!/bin/bash
#
# Bash aliases
#

alias dirsize='du -sh'
alias diskspace='df -h'
alias rot13='tr A-MN-Za-mn-z N-ZA-Mn-za-m'
unalias screenopen 2>/dev/null # TODO delete by Feb 1 2017
alias sortc='sort | uniq -c | sort -nr'
[[ $OSTYPE == "darwin"* ]] && alias opentw='open -a TextWrangler'

# Adds a 'clipboard' command to pipe into, that writes to the system clipboard
#   command_whos_output_i_want_to_paste | clipboard
# Calling clipboard on its own writes the current clipboard contents to stdout
# See also http://williammitchell.blogspot.com/2008/03/fun-with-cygwins-devclipboard.html
[[ -e /dev/clipboard ]] && alias clipboard="if_stdin 'cat > /dev/clipboard' 'cat /dev/clipboard'"  # Cygwin
command -v pbcopy >& /dev/null && alias clipboard="if_stdin 'pbcopy' 'pbpaste'"                    # OSX
command -v xclip >& /dev/null && alias clipboard="if_stdin 'xclip -sel clip' 'xclip -o -sel clip'" # Ubuntu

# Adds an 'open' command which attempts to open the passed file with a GUI
# program, such as a text editor.
command -v cygstart >& /dev/null && alias open='cygstart'             # Cygwin
command -v xdg-open >& /dev/null && alias open='xdg-open > /dev/null' # Ubuntu

: # leave at the bottom to prevent the above && block from making this script return non-zero
