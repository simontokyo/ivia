#!/bin/bash

# Get directory for this script
RUNDIR="`dirname \"$0\"`"         # relative
RUNDIR="`( cd \"$RUNDIR\" && pwd )`"  # absolutized and normalized
if [ -z "$RUNDIR" ] ; then
  echo "Failed to get local path"
  exit 1  # fail
fi

# Get environment from common/env-config.sh
. $RUNDIR/../common/env-config.sh

# Set file locations
PROJECT=${RUNDIR}/iamlab
YAML=${PROJECT}/docker-compose.yaml

# Create a temporary working directory
TMPDIR=/tmp/backup-$RANDOM$RANDOM
mkdir $TMPDIR

# CD to project to pick up .env file
CUR_DIR=`pwd`
cd ${PROJECT}

# Get docker container ID for iviaconfig container
ISVACONFIG="$(docker-compose -f ${YAML} ps -q iviaconfig)"

# Copy the current snapshots from iviaconfig container
SNAPSHOTS=`docker exec ${ISVACONFIG} ls /var/shared/snapshots`
for SNAPSHOT in $SNAPSHOTS; do
docker cp ${ISVACONFIG}:/var/shared/snapshots/$SNAPSHOT $TMPDIR
done

# Get docker container ID for openldap container
OPENLDAP="$(docker-compose -f ${YAML} ps -q openldap)"

# Extract LDAP Data from OpenLDAP
docker exec -- ${OPENLDAP} ldapsearch -H "ldaps://localhost:636" -L -D "cn=root,secAuthority=Default" -w "Passw0rd" -b "secAuthority=Default" -s sub "(objectclass=*)" > $TMPDIR/secauthority.ldif
docker exec -- ${OPENLDAP} ldapsearch -H "ldaps://localhost:636" -L -D "cn=root,secAuthority=Default" -w "Passw0rd" -b "dc=ibm,dc=com" -s sub "(objectclass=*)" > $TMPDIR/ibmcom.ldif

# Get docker container ID for postgresql container
POSTGRESQL="$(docker-compose -f ${YAML} ps -q postgresql)"
docker exec -- ${POSTGRESQL} /usr/local/bin/pg_dump ivia > $TMPDIR/ivia.db

cp -R ${DOCKERKEYS} ${TMPDIR}
cd ${CUR_DIR}
tar -cvf ivia-backup-$RANDOM.tar -C ${TMPDIR} .
rm -rf ${TMPDIR}
echo Done.
