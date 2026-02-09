#!/bin/bash
  
# Get directory for this script
RUNDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
if [ -z "$RUNDIR" ] ; then
  echo "Failed to get local path"
  exit 1  # fail
fi

# Get environment from common/env-config.sh
. $RUNDIR/env-config.sh

LDAP_CERT_DN="/CN=openldap/O=ibm/C=us"
POSTGRES_CERT_DN="/CN=postgresql/O=ibm/C=us"
ISVAOP_CERT_DN="/CN=isvaop.ibm.com/O=ibm/C=us"

if [ ! -d "$DOCKERKEYS" ]; then mkdir $DOCKERKEYS; fi
if [ ! -d "$DOCKERKEYS/openldap" ]; then mkdir $DOCKERKEYS/openldap; fi
if [ ! -d "$DOCKERKEYS/postgresql" ]; then mkdir $DOCKERKEYS/postgresql; fi
if [ ! -d "$DOCKERKEYS/isvaop" ]; then mkdir $DOCKERKEYS/isvaop; fi
if [ ! -d "$DOCKERKEYS/isvaop/personal" ]; then mkdir $DOCKERKEYS/isvaop/personal; fi
if [ ! -d "$DOCKERKEYS/isvaop/signer" ]; then mkdir $DOCKERKEYS/isvaop/signer; fi

if [ ! -f "$DOCKERKEYS/openldap/ldap.key" ] || [ ! -f "$DOCKERKEYS/openldap/ldap.crt" ]
then
	echo "Creating LDAP certificate files"
  openssl req -x509 -newkey rsa:4096 -keyout $DOCKERKEYS/openldap/ldap.key -out $DOCKERKEYS/openldap/ldap.crt -days 3650 -subj $LDAP_CERT_DN -nodes
else
	echo "LDAP certificate files found - using existing certificate files"
fi

# Same for dhparam.pem file
if [ ! -f "$DOCKERKEYS/openldap/dhparam.pem" ]
then
	echo "Creating LDAP dhparam.pem"
	openssl dhparam -out "$DOCKERKEYS/openldap/dhparam.pem" 2048
else
	echo "LDAP dhparam.pem file found - using existing file"
fi

cp "$DOCKERKEYS/openldap/ldap.crt" "$DOCKERKEYS/openldap/ca.crt"

if [ ! -f "$DOCKERKEYS/postgresql/postgres.key" ] || [ ! -f "$DOCKERKEYS/postgresql/postgres.crt" ]
then
	echo "Creating postgres certificate files"
  	openssl req -x509 -newkey rsa:4096 -keyout $DOCKERKEYS/postgresql/postgres.key -out $DOCKERKEYS/postgresql/postgres.crt -days 3650 -subj $POSTGRES_CERT_DN -nodes -addext "subjectAltName = DNS:postgresql"
else
	echo "Postgres certificate files found - using existing certificate files"
fi

cat  "$DOCKERKEYS/postgresql/postgres.crt" "$DOCKERKEYS/postgresql/postgres.key" > "$DOCKERKEYS/postgresql/server.pem"
cp "$DOCKERKEYS/postgresql/postgres.crt" ${IVIAOPCONFIG}

if [ ! -f "$DOCKERKEYS/isvaop/personal/isvaop.key" ] || [ ! -f "$DOCKERKEYS/isvaop/signer/isvaop.pem" ]
then
	echo "Creating ISVAOP certificate files"
  openssl req -newkey rsa:2048 -nodes -inform PEM -keyout $DOCKERKEYS/isvaop/personal/isvaop_key.pem -x509 -days 3650 -out $DOCKERKEYS/isvaop/signer/isvaop.pem -subj $ISVAOP_CERT_DN
else
	echo "ISVAOP certificate files found - using existing certificate files"
fi
cp "$DOCKERKEYS/isvaop/personal/isvaop_key.pem" ${IVIAOPCONFIG}
cp "$DOCKERKEYS/isvaop/signer/isvaop.pem" ${IVIAOPCONFIG}
