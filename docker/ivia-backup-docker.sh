#!/bin/bash

# Get directory for this script
RUNDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
if [ -z "$RUNDIR" ] ; then
  echo "Failed to get local path"
  exit 1  # fail
fi

# Get environment from common/env-config.sh
. $RUNDIR/../common/env-config.sh

# Create a temporary working directory
TMPDIR=/tmp/backup-$RANDOM$RANDOM
mkdir $TMPDIR

# Get docker container ID for the config container
ISVACONFIG="iviaconfig"

# Copy the current snapshots from config container
SNAPSHOTS=`docker exec ${ISVACONFIG} ls /var/shared/snapshots`
for SNAPSHOT in $SNAPSHOTS; do
docker cp ${ISVACONFIG}:/var/shared/snapshots/$SNAPSHOT $TMPDIR
done

# Get docker container ID for openldap container
OPENLDAP="openldap"

# Extract LDAP Data from OpenLDAP
docker exec -- ${OPENLDAP} ldapsearch -H "ldaps://localhost:636" -L -D "cn=root,secAuthority=Default" -w "Passw0rd" -b "secAuthority=Default" -s sub "(objectclass=*)" > $TMPDIR/secauthority.ldif
docker exec -- ${OPENLDAP} ldapsearch -H "ldaps://localhost:636" -L -D "cn=root,secAuthority=Default" -w "Passw0rd" -b "dc=ibm,dc=com" -s sub "(objectclass=*)" > $TMPDIR/ibmcom.ldif

# Get docker container ID for postgresql container
POSTGRESQL="postgresql"
docker exec -- ${POSTGRESQL} /usr/local/bin/pg_dump ivia > $TMPDIR/ivia.db

cp -R ${DOCKERKEYS} ${TMPDIR}

tar -cf ivia-backup-$RANDOM.tar -C ${TMPDIR} .
rm -rf ${TMPDIR}
echo Done.
