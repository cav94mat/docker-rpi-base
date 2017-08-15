#!/bin/bash
## Event handlers
# @event    Called on image creation
on_install() {
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
    
    task "Done"
}
# @event    Main container startup code
on_run() {
    ## Mount volumes ##
    task "Mounting volumes"
    v-perm "/conf" "/data"
    #v-perm -r "/etc"          
    #v-bind "/conf/nginx" "/etc/nginx" -- "nginx.conf"
 
    task "Starting"
    ## Main run ##
    
    run "nginx" #OR: run --root "nginx"
}
# @event    Shutdown procedure (container stop request)
on_term() {
    task "Stopping"
    run-signal -w 'SIGQUIT' # -w: Await process termination
}

# Invoke the run.lib.sh entry point
source "run.lib.sh"
