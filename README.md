# util.gem - General Bash Utilities

TODO

## Key Features

### Functions

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

## Customizations
