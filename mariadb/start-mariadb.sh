#!/bin/bash -x

# startup a new database server

set -e

test $# -ne 2 && (echo "error: args missing"; exit 1)

cname=$1
server_id=$2

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

start_node() {
    server_cnf="server.cnf"
    server_cnf_file="$region_tmp_dir/server.cnf"
    test -f $server_cnf_file | rm -f $server_cnf_file
    create_server_conf $server_cnf_file

    echo "starting container '$cname'"
    docker run -d --name $cname \
        --network host \
        -e DEBUG=YES -e MYSQL_ROOT_PASSWORD=$DB_ROOT_PASSWORD \
        -v $server_cnf_file:/etc/mysql/conf.d/$server_cnf:ro \
        mariadb:10.0 mysqld --replicate-do-db=keystone \
            --replicate-ignore-db=mysql > /dev/null
}

mkdir -p $region_tmp_dir

start_node

