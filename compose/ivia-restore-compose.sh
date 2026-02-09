#!/bin/bash

# Set file locations
PROJECT="`dirname \"$0\"`"         # relative
PROJECT="`( cd \"$PROJECT/iamlab\" && pwd )`"  # absolutized and normalized
if [ -z "$PROJECT" ] ; then
  echo "Failed to get local path"
  exit 1  # fail
fi
YAML=${PROJECT}/docker-compose.yaml

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

# CD to compose project to pick up .env
cd ${PROJECT}

# Get docker container ID for openldap container
OPENLDAP="$(docker-compose -f ${YAML} ps -q openldap)"

# Restore LDAP Data to OpenLDAP
echo "Loading LDAP Data..."
docker cp ${TMPDIR}/secauthority.ldif ${OPENLDAP}:/tmp/secauthority.ldif
docker exec -- ${OPENLDAP} ldapadd -c -f /tmp/secauthority.ldif -H "ldaps://localhost:636" -D "cn=root,secAuthority=Default" -w "Passw0rd" > /tmp/ivia-restore.log 2>&1
docker cp ${TMPDIR}/ibmcom.ldif ${OPENLDAP}:/tmp/ibmcom.ldif
docker exec -- ${OPENLDAP} ldapadd -c -f /tmp/ibmcom.ldif -H "ldaps://localhost:636" -D "cn=root,secAuthority=Default" -w "Passw0rd" >> /tmp/ivia-restore.log 2>&1
docker exec -- ${OPENLDAP} rm /tmp/secauthority.ldif
docker exec -- ${OPENLDAP} rm /tmp/ibmcom.ldif

# Get docker container ID for postgresql container
POSTGRESQL="$(docker-compose -f ${YAML} ps -q postgresql)"

# Restore DB
echo "Loading DB Data..."
docker exec -i -- ${POSTGRESQL} /usr/local/bin/psql ivia < ${TMPDIR}/ivia.db >> /tmp/ivia-restore.log 2>&1

# Get docker container ID for iviaconfig container
ISVACONFIG="$(docker-compose -f ${YAML} ps -q iviaconfig)"

# Copy snapshots to the iviaconfig container
echo "Copying Snapshot..."
SNAPSHOTS=`ls ${TMPDIR}/*.snapshot`
for SNAPSHOT in $SNAPSHOTS; do
docker cp ${SNAPSHOT} ${ISVACONFIG}:/var/shared/snapshots
done

rm -rf $TMPDIR

# Restart environment to apply updated files
echo "Restarting Config Container..."
docker-compose -f ${YAML} restart

echo "Done."
