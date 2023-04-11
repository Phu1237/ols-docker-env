#!/usr/bin/env bash
CONT_NAME='litespeed'
EPACE='        '

echow(){
    FLAG=${1}
    shift
    echo -e "\033[1m${EPACE}${FLAG}\033[0m${@}"
}

help_message(){
    echo -e "\033[1mOPTIONS\033[0m"
    echow "-A, --add [domain_name]"
    echo "${EPACE}${EPACE}Example: domain.sh -A example.com, will add the domain to Listener and auto create a new virtual host."
    echow "-D, --del [domain_name]"
    echo "${EPACE}${EPACE}Example: domain.sh -D example.com, will delete the domain from Listener."
    echow "-m, --make [domain_name]"
    echo "${EPACE}${EPACE}Example: domain.sh -M example.com, will create diretories for domain from Listener."
    echow "-c, --clean [domain_name]"
    echo "${EPACE}${EPACE}Example: domain.sh -C example.com, will remove diretories and config file of domain from Listener."
    echow '-H, --help'
    echo "${EPACE}${EPACE}Display help and exit."
}

check_input(){
    if [ -z "${1}" ]; then
        help_message
        exit 1
    fi
}

add_domain(){
    check_input ${1}
    docker compose exec ${CONT_NAME} su -s /bin/bash lsadm -c "cd /usr/local/lsws/conf && domainctl.sh --add ${1}"
    if [ ! -d "./sites/${1}" ]; then
        mkdir -p ./sites/${1}/{html,logs,certs}
    fi
    bash bin/webadmin.sh -r
}

del_domain(){
    check_input ${1}
    docker compose exec ${CONT_NAME} su -s /bin/bash lsadm -c "cd /usr/local/lsws/conf && domainctl.sh --del ${1}"
    bash bin/webadmin.sh -r
}

make_dir(){
    check_input ${1}
    docker compose exec ${CONT_NAME} su -s /bin/bash lsadm -c "cd /usr/local/lsws/conf && mkdir -p sites/${1}/{html,logs,certs,conf} && chown lsadm:lsadm sites/${1}/conf"
    echo "Please create new Virtual host on your LiteSpeed WebAdmin Console with above information"
    echo "! Virtual Host Root: sites/${1}/"
    echo "! Config File: \$SERVER_ROOT/conf/vhosts/${1}/vhconf.conf"
    echo "! Document Root: \$VH_ROOT/html/"
    echo "! Domain Name: ${1}"
    echo "! Domain Allias: www.${1} (if needed)"
    echo "And remember to add created Virtual host to Listeners 80 and 443"
}

clean(){
    check_input ${1}
    docker compose exec ${CONT_NAME} su -s /bin/bash lsadm -c "cd /usr/local/lsws/conf && rm -rf sites/${1} && rm -rf /usr/local/lsws/conf/${1}"
}

check_input ${1}
while [ ! -z "${1}" ]; do
    case ${1} in
        -[hH] | -help | --help)
            help_message
            ;;
        -[aA] | -add | --add) shift
            add_domain ${1}
            ;;
        -[dD] | -del | --del | --delete) shift
            del_domain ${1}
            ;;
        -[mM] | -make | --make) shift
            make_dir ${1}
            ;;
        -[cC] | -clean | --clean) shift
            clean ${1}
            ;;
        *)
            help_message
            ;;
    esac
    shift
done
