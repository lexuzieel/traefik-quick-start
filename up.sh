#/bin/bash

address() {
  ip -brief address show $1 | awk '{print $3}' | cut -d/ -f1 | head -n 1
}

log_i() {
    log "[INFO] ${@}"
}

log_e() {
    log "[ERROR] ${@}"
}

log_d() {
    if [ -n "$DEBUG" ]; then
        log "[DEBUG] ${@}"
    fi
}

parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case $1 in
        --external)
            shift
            if [ -z $1 ]; then
                log_e "External interface name must not be empty"
                exit 1
            fi

            export EXTERNAL_IP=$(address $1)
            ;;
        --internal)
            shift
            if [ -z $1 ]; then
                log_e "Internal interface name must not be empty"
                exit 1
            fi

            export INTERNAL_IP=$(address $1)
            ;;
        --internal-port)
            shift
            if [ -z $1 ]; then
                log_e "Internal port value must not be empty"
                exit 1
            fi

            export INTERNAL_PORT=$1
            ;;
        esac

        shift
    done
}

parse_arguments $@

docker-compose up -d

