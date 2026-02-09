#!/bin/bash

# Create a temporary working directory
TMPDIR=/tmp/backup-$RANDOM$RANDOM
mkdir $TMPDIR

if [ $# -ne 1 ]
then
  echo "Usage: $0 <archive file>"
  exit 1
fi

if [ ! -f "$1" ]
then
  echo "File not found - $1"
  exit 1
fi

# Unpack archive to temporary directory
tar -xf $1 -C $TMPDIR

# Get docker container ID for openldap container
OPENLDAP="openldap"

# Restore LDAP Data to OpenLDAP
echo "Loading LDAP Data..."
docker cp ${TMPDIR}/secauthority.ldif ${OPENLDAP}:/tmp/secauthority.ldif
docker exec -- ${OPENLDAP} ldapadd -c -f /tmp/secauthority.ldif -H "ldaps://localhost:636" -D "cn=root,secAuthority=Default" -w "Passw0rd" > /tmp/ivia-restore.log 2>&1
docker cp ${TMPDIR}/ibmcom.ldif ${OPENLDAP}:/tmp/ibmcom.ldif
docker exec -- ${OPENLDAP} ldapadd -c -f /tmp/ibmcom.ldif -H "ldaps://localhost:636" -D "cn=root,secAuthority=Default" -w "Passw0rd" >> /tmp/lab-restore.log 2>&1
docker exec -- ${OPENLDAP} rm /tmp/secauthority.ldif
docker exec -- ${OPENLDAP} rm /tmp/ibmcom.ldif

# Get docker container ID for postgresql container
POSTGRESQL="postgresql"

# Restore DB
echo "Loading DB Data..."
docker exec -i -- ${POSTGRESQL} /usr/local/bin/psql ivia < ${TMPDIR}/ivia.db >> /tmp/lab-restore.log 2>&1

# Get docker container ID for config container
ISVACONFIG="iviaconfig"

# Copy snapshots to the config container
echo "Copying Snapshot..."
SNAPSHOTS=`ls ${TMPDIR}/*.snapshot`
for SNAPSHOT in $SNAPSHOTS; do
docker cp ${SNAPSHOT} ${ISVACONFIG}:/var/shared/snapshots
done

rm -rf $TMPDIR

echo "Restarting Config Container..."
# Restart config container to apply updated files
docker restart ${ISVACONFIG}

echo "Done."
