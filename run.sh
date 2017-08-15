#!/bin/bash
## Event handlers
# @event    Called on image creation
on_install() {
    task "INSTALL"
    ## Integrating APT
    #task "Integrating APT repositories" \
    #&& echo "deb http://ppa.launchpad.net/example/package/ubuntu trusty main" >>/etc/apt/sources.list \
    #&& gpg --keyserver pgpkeys.example.com --recv-key 0123456789ABCDEF \
    #|| return 20
    
    ## Updating APT
    task "Updating APT caches" \
    && apt-get update || return 21
    
    ## Installing packages
    task "Installing packages" \
    && apt-get install 'nginx-light' 'openssl' 'curl' 'sed' 'grep' 'mktemp' \
                       'git' 'python-pip' \
    || return 21
    
    task "Cleaning APT" \
    && apt-get clean
    
    task "/INSTALL"
}
# @event    Container first execution only
on_init() {
    task "INIT"
    ## Mount volumes ##
    task "Mounting volumes"
    # Fix perms and ownership
        v-perm "/conf" "/data"
        #v-perm -r "/etc"          
    # Bind volumes
        #v-bind "/conf/nginx" "/etc/nginx" -- "nginx.conf"    
    task "/INIT"
}
# @event    Main container startup code
on_run() {
    task "RUN"
    run "nginx" # <OR> run --root "nginx"
    task "/RUN"
}
# @event    Shutdown procedure (container stop request)
on_term() {
    task "TERM"
    run-signal -w 'SIGQUIT' # -w: Await process termination; default
    task "/TERM"
}
# @event    Health-check is performed.
on_health() {
    return 0; # default: always pass
}
# Invoke the run.lib.sh entry point
source "/lib/run.lib.sh"
