#!/bin/bash

# Get directory for this script
RUNDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
if [ -z "$RUNDIR" ] ; then
  echo "Failed to get local path"
  exit 1  # fail
fi

# Get environment from common/env-config.sh
. $RUNDIR/env-config.sh

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

if [ -d "${DOCKERKEYS}" ]
then
  echo "${DOCKERKEYS} already exists.  Aborting."
  exit 1
fi

mkdir -p ${DOCKERKEYS}
tar -xf $1 -C ${TMPDIR}
cp -R ${TMPDIR}/dockerkeys/* ${DOCKERKEYS}

rm -rf ${TMPDIR}
echo Done.
