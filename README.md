# CKAN using Vagrant

Sets up a basic development installation of CKAN 2.7.2 on CentOS 7.5 using vagrant. I initially used the official CKAN installation guide from [here](https://github.com/ckan/ckan/wiki/How-to-install-CKAN-2.x-on-CentOS-7).

## Start

To start:

```vagrant up```

Then navigate to:

```http://172.16.16.10/```

## Running Commands

Most commands for CKAN are run using paster which must be run under the virtual Python environment. To do this:

```bash
vagrant ssh
sudo su -
su -s /bin/bash - ckan
. /usr/lib/ckan/default/bin/activate
cd /usr/lib/ckan/default/src/ckan
```

Then the commands can be run. For example, to add some test data:

```paster create-test-data -c /etc/ckan/default/development.ini```

To create a sysadmin account:

```paster sysadmin add jmd email=jmd@dm-juniper.gro.uk name=jmd -c /etc/ckan/default/development.ini```

To promote a user to sysadmin:

```paster sysadmin add jmd -c /etc/ckan/default/development.ini```

## Other Files

In the folder other_files there are a few extra scripts that can be used to add customisations.

### Custom Scheme

- add-custom-scheme.sh install release 1.1.0 of ckanext-scheming
- esc_dataset.json is the definition of the new fields
- package_form.html customises the layout of some screens

### DataPusher

- add-datapusher.sh installs the latest table release of DataPusher
- datapusher.conf
- datapusher.wsgi

### LDAP

- add-ldap.sh installs the latest version ckanext-ldap

The following environment variables need to be set first:

- CKAN_LDAP_URI - e.g., _ldap://vw16jmdfs.dmj.gro.uk:3268_
- CKAN_AUTH_DN - e.g., _OU=Tech Service accounts,OU=Service Accounts,OU=DMJ,DC=DM-Juniper,DC=gro,DC=uk_
- CKAN_BASE_DN - e.g., _OU=Users,OU=JMD,DC=DM-Juniper,DC=gro,DC=uk_
- CKAN_AUTH_USER
- CKAN_AUTH_PASSWORD