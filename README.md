# Template for Docker images based on [cav94mat/rpi-base](//github.com/cav94mat/docker-rpi-base)
Template image for Docker containers on Raspberry Pi (armhf), based on [cav94mat/rpi-base](//github.com/cav94mat/docker-rpi-base).

> :warning: Both this template and the base image are experimental. You should refrain from using them until
  maturity and better stability are achieved.

## 1. File structure
For simplicity, all my images are based on the following structure:

* **run.sh**: Main script. All the container event handlers are defined here,
  so here's where you'll want to write most of your code (see the paragraph 2 below).
  * **run.lib.sh**: This contains common functions, variables and initialization code. You should never edit this file.
* **Dockerfile**: Required by Docker, like usual. Most likely you do **NOT** want to alter this one.

## 2. Editing _run.sh_
The run script is a bash script, composed of various functions (**event handlers**):

* **on_install**: Invoked when the image is built.
  The image building process will fail if this function returns a non-zero exit code.
* **on_init**: Invoked when the container is run for the first time.
* **on_run**: Invoked whenever the container is started (after __on_init__ during the first startup).
* **on_term**: Invoked whenever the container is requested to stop.
  Code here should ideally take less than 10 seconds to execute.
* **on_health**: Invoked whenever Docker checks the healt-state of the container.
  An _unhealthy_ state is reported if this function returns a non-zero exit code.

### 2.1. _on_install_
Generally, one-time container configuration and first packages installation is performed here.

For now, `apt-get` should be used to perform installations; in future, a distribution-agnostic `pkg` wrapper will be made
available. See the paragraph 4 for further information about available commans.

### 2.2. _on_init_
Volumes binding, (optional and non critical) upgrades, and other tasks that should generally be performed just once,
when the users run (or remove and re-run) the container, should be placed here.

> The difference with `on_install` is that the code in this function is run all the times your image is used in a container,
  in the user machine. Unlike `on_run`, though, the code is executed just once per container.

### 2.3. _on_run_
This is the main even handler, that should generally start the main process and sync with it until its termination.
If there are tasks that should be run every time before the container is started, this is where you want them to be.

The `run` function should be used to launch the process. It implicitly starts it using a non-root user (`box`) that
is created automatically during initialization, unless otherwise specified. See the paragraph 4 for further information.

### 2.4. _on_term_
Code to be run whenever the container is requested to stop. Generally it sends a signal to the process previously
invoked with `run`. To do so, the special `run-signal` function is used, usually having a `SIGxxx` as first positional parameter,
which indicates the signal to send. Refer to paragraph 4 for further information.

### 2.5. _on_health_
Function that is executed periodically, according to the settings specified in the Dockerfile or the container run arguments,
and that determines (by simply returning a `1` exit code) whether the container is functioning properly or not.

## 3. Tweaking the Dockerfile
You should **NOT** tweak the Dockerfile for the following reasons:

* Executing commands with `RUN` during the image generation (see paragraph 2.1 instead)
* Setting the main executable with `CMD` (see paragraph 2.3 instead)
* Setting the health-check command with `HEALTHCHECK` (see paragraph 2.5 instead)
* Setting the user that will run the commands with `USER` (see paragraph 2.3 and 4 instead)
* Setting the stop signal with `STOPSIGNAL` (see paragraph 2.4 instead)

You should use it, instead to:
* Define `VOLUME`s
* Define `EXPOSE`d ports
* `ADD` or `COPY` files into the container

## 4. run.sh API reference
The following functions are exposed by the **run.lib.sh** library:

### 4.1. Run functions
Used to launch and control the main process.

#### 4.1.1. run
Launches a process, allowing signal trapping to occur in background.

##### Synopsis:
```xml
run [<<flags>>] <program> [<<args>>]
```

##### Supported flags:
* `--root`: Run the program as root.

#### 4.1.2. run-pid
Retrieves the PID associated to the last program launched with run.
It doesn't guarantee that the process still exists.

##### Synopsis:
```sh
echo $(run-pid) # Prints the PID to STDOUT
```

#### 4.1.3. run-signal
Sends a signal to the process previously launched with run.

##### Synopsis:
```xml
run-signal [<<flags>>] [<signal="SIGTERM">]
```
If no signal is specified, `SIGTERM` is implied.

##### Supported flags:
* `-w`, `--await-termination`: Awaits the process to terminate.

### 4.2. Volumes management
Used to bind volumes to internal directory paths and fix ownership and permissions.

#### 4.2.1. v-bind
Binds a volume to an internal directory path.

##### Synopsis:
```xml
v-bind [<<flags>>] <volume> <mount-path>
```

##### Supported flags:
* `-b <file>` (`--backup`): If the `<file>` exists both in _volume_ and _mount-path_, the mount-path's one is
  renamed to `<file>.original` before any overwriting takes place.

#### 4.2.2. v-perm
Recursively fix a volume or directory ownership and permissions.

* Ownership is set to `root:$GID` (`$GID` is defined in the Dockerfile or at run),
* R/W permissions are added for both the owner and the group (`chmod -R ug+rw`).
  * If `--readonly` is specified, W permission is removed for the group (`chmod -R g-w`).
  
##### Synopsis:
```xml
v-perm [<<flags>>] <volume> [<volume2> ...]
```

##### Supported flags:
* `-r` (`--read-only`): Remove W permission for the group.

### 4.3. Logging
Used to report messages to the container log (accessible with `docker logs <container>`).

#### 4.3.1. info
Used to report an informative message.

##### Synopsis:
```xml
info <message> [...]
```

> The usage is similar to the shell `echo` builtin. Multiple parameters are concatenated into one.

#### 4.3.2. warn
Used to report a warning message.

> Usage is identical to `info` (see above).

#### 4.3.3. error
Used to report an error message.

> Usage is identical to `info` and `warn` (see above).

## 5. Planned features
See the issue-tracker for details.
