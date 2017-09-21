#!/bin/bash
#
# Bash aliases
#

alias dirsize='du -sh'
alias diskspace='df -h'
alias rot13='tr A-MN-Za-mn-z N-ZA-Mn-za-m'
alias sortc='sort | uniq -c | sort -nr'

# Adds a 'clipboard' command to pipe into, that writes to the system clipboard
#   command_whos_output_i_want_to_paste | clipboard
# Calling clipboard on its own writes the current clipboard contents to stdout
command -v pbcopy &> /dev/null && alias clipboard="if_stdin 'pbcopy' 'pbpaste'"                          # OSX
command -v xclip &> /dev/null && alias clipboard="if_stdin 'xclip -sel clip' 'xclip -o -sel clip'"       # Ubuntu
# WSL must come before Cygwin, since Cygwin also has clip.exe on the path
command -v clip.exe &> /dev/null && alias clipboard="if_stdin 'clip.exe' 'pgem_err paste not supported'" # WSL
# See also http://williammitchell.blogspot.com/2008/03/fun-with-cygwins-devclipboard.html
[[ -e /dev/clipboard ]] && alias clipboard="if_stdin 'cat > /dev/clipboard' 'cat /dev/clipboard'"        # Cygwin

# Adds an 'open' command which attempts to open the passed file with a GUI
# program, such as a text editor.
command -v xdg-open &> /dev/null && alias open='xdg-open > /dev/null' # Ubuntu
#   WSL must come before Cygwin, since Cygwin also has cmd.exe on the path
#   https://superuser.com/a/1182349/16275
command -v cmd.exe  &> /dev/null && alias open='cmd.exe /c start "" ' # WSL
command -v cygstart &> /dev/null && alias open='cygstart'             # Cygwin

: # leave at the bottom to prevent the above && block from making this script return non-zero
