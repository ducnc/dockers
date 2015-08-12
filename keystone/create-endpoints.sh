#!/bin/bash

set -e

[[ $DEBUG ]] && set -x

die() {
    echo $1
    exit 1
}

. /opt/kolla/crux.sh

test -z $KEYSTONE_MASTER_PORT_35357_TCP_ADDR && die "error: missing Keystone master link"
test -z $KEYSTONE_PORT_35357_TCP_ADDR && die "error: missing Keystone link"
test -z $OS_TOKEN && die "error: missing env var OS_TOKEN"
test -z $OS_USERNAME && die "error: missing env var OS_USERNAME"
test -z $OS_PASSWORD && die "error: missing env var OS_PASSWORD"
test -z $REGION_NAME && die "error: missing env var REGION_NAME"

export OS_URL=http://$KEYSTONE_MASTER_PORT_35357_TCP_ADDR:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_PROJECT_DOMAIN_NAME=default

crux_endpoint $REGION_NAME identity public http://$KEYSTONE_PORT_5000_TCP_ADDR:5000
crux_endpoint $REGION_NAME identity internal http://$KEYSTONE_PORT_5000_TCP_ADDR:5000
crux_endpoint $REGION_NAME identity admin http://$KEYSTONE_PORT_35357_TCP_ADDR:35357

