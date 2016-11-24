#!/bin/bash

# startup a new database server
set -e

test $# -ne 3 && (echo "error: args missing"; exit 1)

cname=$2
server_id=$3
role=$1

region_tmp_dir="/etc/container/$cname"

create_server_conf() {
    filename=$1

    cat > $filename << EOF
[mysqld]
server_id=$server_id
report-host=$cname
report-port=3306

bind-address = 0.0.0.0
default_storage_engine=InnoDB
innodb_file_per_table
collation-server = utf8_general_ci
init-connect = 'SET NAMES utf8'
character-set-server = utf8

binlog_format=ROW
innodb_autoinc_lock_mode=2
innodb_locks_unsafe_for_binlog=1

# skip host cache with client info
skip-host-cache

# disable DNS host name lookups
skip-name-resolve

# GTID & binlog for master/slave replication
gtid_domain_id=1
log_bin=binlog
log_bin_index=binlog.index
log_slave_updates=1
expire_logs_days=7
slave_net_timeout=60
basedir=/usr
datadir=/var/lib/mysql
EOF
}


function create_master_conf ()
{
    filename=$1
    cat > $filename << EOF
[mysqld]
#GTID giong nhau o 3 node
gtid_domain_id=1
#Server ID khac nhau o 3 node
server_id=$server_id
binlog-do-db=keystone
binlog_format=ROW
log_slave_updates=1
log_bin=binlog
log_bin_index=binlog.index
report-host=master
report-port=3306
EOF
}    # ----------  end of function create_master_conf  ----------


start_node() {
    server_cnf="server.cnf"
    server_cnf_file="$region_tmp_dir/server.cnf"
    test -f $server_cnf_file | rm -f $server_cnf_file

    if [[ $role == 'master' ]]; then
        create_master_conf $server_cnf_file
        port=3304
    elif [[ $role == 'slave' ]]; then
        create_server_conf $server_cnf_file
        port=3305
    fi

    echo "starting container '$cname'"
    docker run -d --name $cname \
        -e DEBUG=YES -e MYSQL_ROOT_PASSWORD=$DB_ROOT_PASSWORD \
        -p $port:3306 \
        -v $server_cnf_file:/etc/mysql/conf.d/$server_cnf:ro \
        mariadb:10.0 mysqld --replicate-do-db=keystone \
            --replicate-ignore-db=mysql > /dev/null
}

mkdir -p $region_tmp_dir

start_node
