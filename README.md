# util.gem - General Bash Utilities

This gem contains several functions and aliases considered (by the author) to
be generally useful. By design the functionality in this gem are **entirely
additive**, meaning nothing in your current environment should be changed by
including these utilities. For most users there's no harm in including this
gem even if you don't intend to use any of its features.

Note: while most vanilla shell environments will not conflict with the names
used by this gem, it's impossible to guarantee the names chosen won't
conflict with some other application or utility. If a name used here
collides with a common utility please file a bug.

## Key Features

*See the associated files (`aliases.sh`, `functions.sh`, etc.) for a complete
list of functionality provided.*

### Aliases

*   `clipboard` accesses the system clipboard cross-platform (Linux, OSX, and
    Cygwin currently). Supports both setting the clipboard (via stdin) and
    reading from it.

    ```
    # writes the output of my_command to the clipboard
    $ my_command | clipboard
    # pipes the current clipboard contents into another_command
    $ clipboard | another_command
    ```

*   `open` opens the argument in the system-associated GUI application such as
    an image viewer or word processor. Intended to replicates the OSX
    [`open`](https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man1/open.1.html)
    command, currently supported on Linux and Cygwin.

*   `dirsize` and `diskspace` - the former takes a directory as an argument and
     prints its size, the latter prints the available and total disk space.
     Both use a human-readable format.

*    `sortc` sorts and counts the unique lines piped to stdin, and orders them
     from most to least common.

### Functions

*   `quiet_success` runs a command, suppressing its output unless the process
    fails. Useful for noisy commands that are only important when they fail,
    such as some unit testing utilities.

*   `emailme` takes a command and executes it, emailing you when it's done.
    Relies on `sendmail` being configured correctly, and reads the `EMAIL`
    environment variable to determine where to send to.

*   `screens` prints a list of currently open `screen` sessions, and
    `screenopen` opens an existing screen session (or creates a new one) in a
    user-friendly way. Power-users will prefer sticking with `screen` or their
    own custom aliases, but `screenopen` gives lay-users easy access to
    `screen`'s key functionality - detachable shell sessions.

*   `gitsyncfork` syncs a Git repository with its upstream master. Useful for
    pulling in updates to a forked GitHub repo.

*   `wait_ext` blocks until the PIDs passed as arguments are finished.
    Useful for waiting for commands running in other terminals.

    ```
    $ long_running_command & wait # prints the PID
    ```

    ```
    $ wait_ext PID && delayed_command
    ```

*   `wait_port` blocks until the ports passed as arguments are listening for
    requests. Useful for running a command once a service comes online, e.g.

    ```
    $ wait_port 1234 && send_request_to 1234
    ```

### Behavior

Displays the names of any open `screen` sessions when a new shell is launched.

## Copyright and License

Copyright 2016-2017 Michael Diamond

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.