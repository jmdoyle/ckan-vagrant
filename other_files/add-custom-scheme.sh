#!/bin/bash
echo 'Add Custom Scheme'
cd /usr/lib/ckan
. default/bin/activate
cd /usr/lib/ckan/default/src
git clone https://github.com/ckan/ckanext-scheming
cd ckanext-scheming
git checkout tags/release-1.1.0 -b tags/release-1.1.0
pip install -r requirements.txt
python setup.py develop
cp /vagrant/other_files/esc_dataset.json /usr/lib/ckan/default/src/ckanext-scheming/ckanext/scheming/esc_dataset.json
cp /vagrant/other_files/package_form.html /usr/lib/ckan/default/src/ckanext-scheming/ckanext/scheming/templates/scheming/package/snippets/package_form.html
current_plugins=`crudini --get /etc/ckan/default/development.ini app:main ckan.plugins`
crudini --set /etc/ckan/default/development.ini app:main ckan.plugins "${current_plugins} scheming_datasets"
crudini --set /etc/ckan/default/development.ini app:main scheming.dataset_schemas ckanext.scheming:esc_dataset.json
# Use an expanded license list
crudini --set /etc/ckan/default/development.ini app:main licenses_group_url http://licenses.opendefinition.org/licenses/groups/all.json
deactivate
systemctl restart httpd.service
