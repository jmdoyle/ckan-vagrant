#!/bin/bash
echo 'Installing necessary tools'
yum install -y wget policycoreutils-python
yum install -y epel-release
yum install -y crudini
yum install -y xml-commons git subversion mercurial postgresql-server postgresql-devel \
postgresql python-devel libxslt libxslt-devel libxml2 libxml2-devel python-virtualenv \
gcc gcc-c++ make java-1.6.0-openjdk-devel java-1.6.0-openjdk redis tomcat tomcat-webapps \
tomcat-admin-webapps xalan-j2 unzip policycoreutils-python mod_wsgi httpd

echo 'Adding CKAN user'
useradd -m -s /sbin/nologin -d /usr/lib/ckan -c "CKAN User" ckan
chmod 755 /usr/lib/ckan

echo 'Set up isolated Python environment'
su -s /bin/bash - ckan
cd /usr/lib/ckan
virtualenv --verbose --no-site-packages default
. default/bin/activate
echo 'Download and install CKAN'
pip install --upgrade pip
pip install setuptools==36.1
pip install --ignore-installed pytz six
pip install --ignore-installed -e git+https://github.com/okfn/ckan.git@ckan-2.7.2#egg=ckan
pip install --ignore-installed -r default/src/ckan/requirements.txt
deactivate
su root

echo 'Set up PostgreSQL'
systemctl enable postgresql.service
service postgresql initdb
cp /vagrant/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf
systemctl start postgresql.service
sudo -u postgres psql -c "update pg_database set encoding = pg_char_to_encoding('UTF8')"
sudo -u postgres psql -c "CREATE USER ckan_default WITH PASSWORD 'pass';"
sudo -u postgres psql -c "CREATE DATABASE ckan_default OWNER = ckan_default ENCODING = 'utf-8'"
sudo -u postgres psql -l

echo 'Create a CKAN Configuration'
mkdir -p /etc/ckan/default
chown -R ckan /etc/ckan/
su -s /bin/bash - ckan
. default/bin/activate
cd /usr/lib/ckan/default/src/ckan
paster make-config ckan /etc/ckan/default/development.ini
crudini --set /etc/ckan/default/development.ini app:main solr_url "http://127.0.0.1:8080/solr/ckan-schema-2.7"
crudini --set /etc/ckan/default/development.ini app:main ckan.site_url "http://172.16.16.10"
deactivate
su root

echo 'Set up Apache SOLR'
curl http://archive.apache.org/dist/lucene/solr/1.4.1/apache-solr-1.4.1.tgz | tar xzf -
mkdir -p /usr/share/solr/core0 /var/lib/solr/data/core0 /etc/solr/core0
cp apache-solr-1.4.1/dist/apache-solr-1.4.1.war /usr/share/solr
cp -r apache-solr-1.4.1/example/solr/conf /etc/solr/core0
sed -i 's/<dataDir>.*<\/dataDir>/<dataDir>${dataDir}<\/dataDir>/' /etc/solr/core0/conf/solrconfig.xml
ln -s /etc/solr/core0/conf /usr/share/solr/core0/conf
rm -f /etc/solr/core0/conf/schema.xml
ln -s /usr/lib/ckan/default/src/ckan/ckan/config/solr/schema.xml /etc/solr/core0/conf/schema.xml
cat >/etc/tomcat/Catalina/localhost/solr.xml <<EOL
<Context docBase="/usr/share/solr/apache-solr-1.4.1.war" debug="0" privileged="true" allowLinking="true" crossContext="true">
    <Environment name="solr/home" type="java.lang.String" value="/usr/share/solr" override="true" />
</Context>
EOL
cat >/usr/share/solr/solr.xml <<EOL
<solr persistent="true" sharedLib="lib">
    <cores adminPath="/admin/cores">
        <core name ="ckan-schema-2.7" instanceDir="core0">
            <property name="dataDir" value="/var/lib/solr/data/core0" />
        </core>
    </cores>
</solr>
EOL
chown -R tomcat:tomcat /usr/share/solr /var/lib/solr
systemctl enable tomcat.service
systemctl start tomcat.service

echo 'Create the database tables'
systemctl enable redis.service
systemctl start redis.service
chown -R ckan /usr/lib/ckan
su -s /bin/bash - ckan
cd /usr/lib/ckan
. default/bin/activate
cd /usr/lib/ckan/default/src/ckan
paster db init -c /etc/ckan/default/development.ini
ln -s /usr/lib/ckan/default/src/ckan/who.ini /etc/ckan/default/who.ini
deactivate
su root

echo 'Create a WSGI file'
cp /vagrant/apache.wsgi /etc/ckan/default/apache.wsgi

echo 'Create the Apache config file'
cp /vagrant/ckan_default.conf /etc/httpd/conf.d/ckan_default.conf

echo 'Configure Apache'
chkconfig httpd on
service httpd start

echo 'Configure SELinux'
# This is necessary if SELinux is enabled (see /etc/sysconfig/selinux)
if [ `getenforce` = 'Enforcing' ]; then
  setsebool -P httpd_can_network_connect on
fi

echo 'Add DataStore'
sudo -u postgres psql -c "CREATE USER datastore_default WITH PASSWORD 'pass';"
sudo -u postgres psql -c "CREATE DATABASE datastore_default OWNER = ckan_default ENCODING = 'utf-8'"
crudini --set /etc/ckan/default/development.ini app:main ckan.datastore.write_url "postgresql://ckan_default:pass@localhost/datastore_default"
crudini --set /etc/ckan/default/development.ini app:main ckan.datastore.read_url "postgresql://datastore_default:pass@localhost/datastore_default"
current_plugins=`crudini --get /etc/ckan/default/development.ini app:main ckan.plugins`
crudini --set /etc/ckan/default/development.ini app:main ckan.plugins "${current_plugins} datastore"
cd /usr/lib/ckan
. default/bin/activate
cd /usr/lib/ckan/default/src/ckan
paster --plugin=ckan datastore set-permissions -c /etc/ckan/default/development.ini | sudo -u postgres psql datastore_default --set ON_ERROR_STOP=1

echo 'Add FileStore'
mkdir -p /var/lib/ckan/default
chown -R apache /var/lib/ckan
crudini --set /etc/ckan/default/development.ini app:main ckan.storage_path "/var/lib/ckan/default"
crudini --set /etc/ckan/default/development.ini app:main ckan.max_resource_size 100

systemctl restart httpd.service