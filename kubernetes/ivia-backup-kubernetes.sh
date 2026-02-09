#!/bin/bash

# Get directory for this script
RUNDIR="`dirname \"$0\"`"         # relative
RUNDIR="`( cd \"$RUNDIR\" && pwd )`"  # absolutized and normalized
if [ -z "$RUNDIR" ] ; then
  echo "Failed to get local path"
  exit 1  # fail
fi

. ${RUNDIR}/../common/env-config.sh

# Create a temporary working directory
TMPDIR=/tmp/backup-$RANDOM$RANDOM
mkdir $TMPDIR

# Get docker container ID for iviaconfig container
ISVACONFIG="$(kubectl get --no-headers=true pods -l app=iviaconfig -o custom-columns=:metadata.name)"

# Copy the current snapshots from iviaconfig container
SNAPSHOTS=`kubectl exec ${ISVACONFIG} -- ls /var/shared/snapshots`
for SNAPSHOT in $SNAPSHOTS; do
kubectl cp ${ISVACONFIG}:/var/shared/snapshots/$SNAPSHOT $TMPDIR/$SNAPSHOT
done

# Get docker container ID for openldap container
OPENLDAP="$(kubectl get --no-headers=true pods -l app=openldap -o custom-columns=:metadata.name)"

# Extract LDAP Data from OpenLDAP
kubectl exec ${OPENLDAP} -- ldapsearch -H "ldaps://localhost:636" -L -D "cn=root,secAuthority=Default" -w "Passw0rd" -b "secAuthority=Default" -s sub "(objectclass=*)" > $TMPDIR/secauthority.ldif
kubectl exec ${OPENLDAP} -- ldapsearch -H "ldaps://localhost:636" -L -D "cn=root,secAuthority=Default" -w "Passw0rd" -b "dc=ibm,dc=com" -s sub "(objectclass=*)" > $TMPDIR/ibmcom.ldif

# Get docker container ID for postgresql container
POSTGRESQL="$(kubectl get --no-headers=true pods -l app=postgresql -o custom-columns=:metadata.name)"
kubectl exec ${POSTGRESQL} -- /usr/local/bin/pg_dump ivia > $TMPDIR/ivia.db

cp -R ${DOCKERKEYS} ${TMPDIR}

tar -cvf ivia-backup-$RANDOM.tar -C ${TMPDIR} .
rm -rf ${TMPDIR}
echo Done.
