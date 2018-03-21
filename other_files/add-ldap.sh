#!/bin/bash
echo 'Add LDAP Authentication'
yum install -y python-devel openldap-devel
cd /usr/lib/ckan
. default/bin/activate
cd /usr/lib/ckan
pip install --upgrade pip
pip install -e git+https://github.com/NaturalHistoryMuseum/ckanext-ldap.git#egg=ckanext-ldap
pip install -r default/src/ckanext-ldap/requirements.txt
deactivate
current_plugins=`crudini --get /etc/ckan/default/development.ini app:main ckan.plugins`
crudini --set /etc/ckan/default/development.ini app:main ckan.plugins "${current_plugins} ldap"
crudini --set /etc/ckan/default/development.ini app:main ckanext.ldap.uri "${CKAN_LDAP_URI}"
crudini --set /etc/ckan/default/development.ini app:main ckanext.ldap.auth.dn "CN=${CKAN_AUTH_USER},${CKAN_AUTH_DN}"
crudini --set /etc/ckan/default/development.ini app:main ckanext.ldap.auth.password "${CKAN_AUTH_PASSWORD}"
crudini --set /etc/ckan/default/development.ini app:main ckanext.ldap.base_dn "${CKAN_BASE_DN}"
crudini --set /etc/ckan/default/development.ini app:main ckanext.ldap.search.filter "sAMAccountName={login}"
crudini --set /etc/ckan/default/development.ini app:main ckanext.ldap.username "sAMAccountName"
crudini --set /etc/ckan/default/development.ini app:main ckanext.ldap.email "mail"

systemctl restart httpd.service
