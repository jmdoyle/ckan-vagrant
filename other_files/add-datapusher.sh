#!/bin/bash
echo 'Add DataPusher'
virtualenv /usr/lib/ckan/datapusher
mkdir /usr/lib/ckan/datapusher/src
cd /usr/lib/ckan/datapusher/src
git clone -b stable https://github.com/ckan/datapusher.git
cd /usr/lib/ckan
. datapusher/bin/activate
cd /usr/lib/ckan/datapusher/src/datapusher
pip install --upgrade setuptools
pip install --upgrade pip
pip install -r requirements.txt
python setup.py develop
deactivate

cp deployment/datapusher_settings.py /etc/ckan/default
current_plugins=`crudini --get /etc/ckan/default/development.ini app:main ckan.plugins`
crudini --set /etc/ckan/default/development.ini app:main ckan.plugins "${current_plugins} datapusher"
crudini --set /etc/ckan/default/development.ini app:main ckan.datapusher.url "http://172.16.16.10/"
cp /vagrant/other_files/datapusher.conf /etc/httpd/conf.d/datapusher.conf
cp /vagrant/other_files/datapusher.wsgi /etc/ckan/default/datapusher.wsgi
systemctl restart httpd.service
