#!/bin/bash
readonly _VER='170815A' # Library version

## Globals ##
_PHASE="core"  
_RUN_PROG=      
_RUN_PID=0

## Library functions ##

# @func Bind a volume to the specified path.
#  @syntax  [<<flags>>] <volume> <mount-point>
#  @flag    -b|--backup <filename>: Backup the specified file (use relative paths).
v-bind() {
    declare -a preserve;
    # Arguments
    while [ $# -gt 0 -a "${1:0:1}" = "-" ]; do
        case "$1" in
            "--")
                break
                ;;
            "-b"|"--backup")
                preserve+=("$2")
                shift
                ;;
            *)
                __error "v-bind" "Unsupported option: $1"
                ;;
        esac
        shift
    done
    # Code
    vr="$1"
    vl="$2"
    [ "$vr" -a "$vl" ] || __error "v-bind" "Illegal invocation attempt ('$vr' -> '$vr')."
    if [ ! -h "$vl" ]; then
        __info "v-bind" "Binding volume \"$vl\" -> \"$vr\""
        if [ -d "$vr" ]; then
            cp -RTn "$vl" "$vr"
            for p in "${preserve[@]}"; do
                cp "$vl/$1" "$vr/$p.original" || __warn "v-bind" "Unable to backup '$vl/$p'."
                shift
            done
        elif [ "${preserve[#]}" -gt 0 ]; then
            __warn "v-bind" "Backup option not allowed for non-directory volumes!"
        fi
        rm -Rf "$vl"
        ln -s "$vr" "$vl"
    fi
}
# @func Fix a volume or directory ownership and permissions
#  @syntax [<<options>>] <<volumes>>
#  @flag   -r|--read-only: Mount the volume(s) read-only for the box user.
v-perm() {
    local p_mask="ug+rw"
    # Arguments
    while [ $# -gt 0 -a "${1:0:1}" = "-" ]; do
        case "$1" in
            "--")
                break
                ;;
            "-r"|"--read-only")
                p_mask="$p_mask,g-w"
                ;;
            *)
                __error "v-perm" "Unsupported option: $1"
                ;;
        esac
        shift
    done
    # Code
    while [ "$#" -gt 0 ]; do
        chown -R "root:$GID" "$1"
        chmod -R "$p_mask" "$1" 
        shift
    done
}
#@func Run an executable, allowing signal trapping to occur in the background.
#@syntax [<<flags>>] <program> [<<args>>]
# @flag  --root:    Execute <program> as user 'root', instead of 'box'.
run() {
    local uid="$UID"
    # Arguments
    while [ $# -gt 0 -a "${1:0:1}" = "-" ]; do
        case "$1" in
            "--")
                break
                ;;
            "--root")
                uid=0
                ;;
            *)
                __error "run" "Unsupported option: $1"
                ;;
        esac
        shift
    done
    _RUN_PROG="$1"; shift;
    wlog "I: Starting: $_RUN_PROG $@"
    sudo -u "#$uid" "$_RUN_PROG" "$@" &
    _RUN_PID=$!
    wlog "I: $PROG: Started with pid=`run-pid`"
    wait $_RUN_PID
}
#@func Get the PID associated to the last `run` call.
run-pid() { echo $_RUN_PID; }
#@func Send a signal to the process previously launched with `run`.
#@syntax [<<options>>] [<signal-name>=SIGTERM]
run-signal() {
    local sig="SIGTERM"
    local await=
    # Arguments
    while [ $# -gt 0 -a "${1:0:1}" = "-" ]; do
        case "$1" in
            "--")
                break1
                ;;
            "-w"|"--await-termination")
                await=1
                ;;
            *)
                __error "run-signal" "Unsupported option: $1"
                ;;
        esac
        shift
    done
    # Code
    [ "$1" ] && sig="$1"
    __info "run-signal" "Sending $sig to $_RUN_PROG ($_RUN_PID)..."
    /bin/kill -s "$sig" "$_RUN_PID" || { __warn "run-signal" "/bin/kill raised error $?"; return $?; }
    if [ "$await" ]; then
        __info "run-signal" "Awaiting for $_RUN_PROG ($_RUN_PID) to quit..."
        wait "$_RUN_PID"
        __info "run-signal" "Process terminated."
    fi
}
#@func Main logging function (to STDERR and `docker logs` output)
  wlog()  { logger -s -t "run.sh" "$*"; }
#@func Log task begin point
#@syntax <caption>
  task()  { echo "-- $* --" >&2; }
#@funcs Log informative message
#@syntax <source> <message>
__info()  { wlog "I: $1: $*"; }
#@syntax <message>
  info()  { __info "$F_PHASE" "$@"; }
#@funcs Log warning message
#@syntax <source> <message>
__warn()  { wlog "W: $1: $*"; }
#@syntax <message>
  warn()  { __warn "$F_PHASE" "$@"; }
#@func Log error message and generally quits
#@syntax <source> <message>
__error() { wlog "E: $1: $*"; [ "$keep_alive" ] || exit 100; }
#@syntax <message>
  error() { keep_alive=1 __error "$F_PHASE" "$@"; }
#@func Invoke 'on_term' and cause script termination
__on_term() { _PHASE="on_term"; on_term "$@"; exit $?; }

## Main entry point ##

__main() {
    local f_mode=""
    # Arguments
    while [ "$#" -gt 0 ]; do
        case "$1" in
            "--install")
                f_mode='install'
                ;;
            "--health")
                f_mode='health'
                ;;
            "-?"|"--help")
                __main -V
                echo ""
                echo "Usage:"
                echo " $0 [--install|--health]"
                echo ""
                echo " --install: Invoke image creation script."
                echo " --health:  Invoke health-check script."
                echo ""
                exit 0
                ;;
            "-V"|"--version")
                echo "/bin/run.sh (v. $_VER) by cav94mat"
                exit 0
                ;;
            "--")
                break;
                ;;
            *)
                warn "Illegal option '$1'"
                ;;
        esac
        shift
    done
    # Code
    case "$f_mode" in
        "install")
            _PHASE="on_install"
            # /sbin/wlog
            #task "Generating /sbin/wlog" \
            #&& printf '#!/bin/sh\nlogger -s -t "run.sh" "$*"' >/sbin/wlog \
            #&& chmod +x /sbin/wlog || return 101
            
            # User 'box'
            echo "-- Adding user 'box' ($UID:$GID) --" >&2 \
            && addgroup --gid ${GID} "box" \
            && useradd -d / -s /bin/sh -g "box" -u ${UID} "box" \
            || return 10
            on_install "$@"
            ;;
        "health")
            on_health "$@"
            ;;
        "")    
            trap "__on_term" TERM INT
            if [ ! -f "/.initialized" ]; then
                _PHASE="init"
                on_init "$@"
                date -R >"/.initialized" || error "Could not write '/.initialized'!"
            fi
            _PHASE="run"
            on_run "$@"
            ;;
        *)
            error "Unknown mode."
            ;;
    esac
}
#alias main='__main "$@"';
__main "$@"
