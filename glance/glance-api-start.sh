#!/bin/bash

set -e

[[ $DEBUG ]] && set -x

. /opt/kolla/kolla-common.sh
. /opt/kolla/config-glance.sh

: ${GLANCE_API_SERVICE_HOST:=$PUBLIC_IP}

check_required_vars KEYSTONE_ADMIN_TOKEN KEYSTONE_ADMIN_SERVICE_HOST \
                    OS_USERNAME OS_PASSWORD \
                    GLANCE_KEYSTONE_USER GLANCE_KEYSTONE_PASSWORD \
                    ADMIN_TENANT_NAME GLANCE_API_SERVICE_HOST \
                    PUBLIC_IP GLANCE_REGISTRY_SERVICE_HOST REGION_NAME

fail_unless_os_service_running keystone

. /opt/kolla/crux.sh

export OS_PROJECT_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_AUTH_URL=http://$KEYSTONE_MASTER_PORT_35357_TCP_ADDR:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_USER_DOMAIN_NAME=Default
env | grep OS_
crux_user ${GLANCE_KEYSTONE_PASSWORD} ${GLANCE_KEYSTONE_USER}
crux_role_add service $GLANCE_KEYSTONE_USER admin
crux_service glance image "OpenStack Image"
crux_endpoint $REGION_NAME image public http://$GLANCE_API_SERVICE_HOST:9292
crux_endpoint $REGION_NAME image internal http://$GLANCE_API_SERVICE_HOST:9292
crux_endpoint $REGION_NAME image admin http://$GLANCE_API_SERVICE_HOST:9292

crudini --set /etc/glance/glance-api.conf \
    DEFAULT \
    registry_host \
    "${GLANCE_REGISTRY_SERVICE_HOST}"

sed -i 's/project_domain_id/project_domain_name/g' /etc/glance/glance-api.conf
sed -i 's/user_domain_id/user_domain_name/g' /etc/glance/glance-api.conf
sed -i 's/project_domain_id/project_domain_name/g' /etc/glance/glance-registry.conf
sed -i 's/user_domain_id/user_domain_name/g' /etc/glance/glance-registry.conf


crudini --set /etc/glance/glance-api-paste.ini \
    "filter:authtoken" \
    identity_uri \
    "http://$KEYSTONE_PORT_35357_TCP_ADDR:35357"

crudini --set /etc/glance/glance-api-paste.ini \
    "filter:authtoken" \
    admin_user \
    $GLANCE_KEYSTONE_USER

crudini --set /etc/glance/glance-api-paste.ini \
    "filter:authtoken" \
    admin_password \
    $GLANCE_KEYSTONE_PASSWORD

crudini --set /etc/glance/glance-api-paste.ini \
    "filter:authtoken" \
    admin_tenant_name \
    service

echo "Starting glance-api"
glance-api --version
if [ -z $DEBUG ]; then
    exec glance-api -v
else
    exec glance-api -dv
fi
