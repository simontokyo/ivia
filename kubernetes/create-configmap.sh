#!/bin/bash

# Get directory for this script
RUNDIR="`dirname \"$0\"`"         # relative
RUNDIR="`( cd \"$RUNDIR\" && pwd )`"  # absolutized and normalized
if [ -z "$RUNDIR" ] ; then
  echo "Failed to get local path"
  exit 1  # fail
fi

. ${RUNDIR}/../common/env-config.sh

if [ ! -d "${IVIAOPCONFIG}" ] 
then
  echo "Configuration files not found. "
  exit 1
fi

# Create secret for TLS certificates used by this container
echo "Deleting confimap"
kubectl delete configmap isvaop-config
echo "Creating confimap for isvaop"
kubectl create configmap isvaop-config --from-file=${IVIAOPCONFIG}
echo "Done."