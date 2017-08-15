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
    && apt-get install 'curl' 'sed' 'grep' 'mktemp' 'git' \
    || return 21
    
    task "Cleaning APT" \
    && apt-get clean
    
    task "/INSTALL"
}
# @event    Container first execution only
on_init() {
    task "INIT" 
    task "/INIT"
}
# @event    Main container startup code
on_run() {
    task "RUN"
    error "This image is not meant to be run directly!"
    task "/RUN"
}
# @event    Shutdown procedure (container stop request)
on_term() {
    task "TERM"
    task "/TERM"
}
# @event    Health-check is performed.
on_health() {
    return 1; # Always fail if you attempt to run an health-check on rpi-base.
}
# Invoke the run.lib.sh entry point
source "/lib/run.lib.sh"
