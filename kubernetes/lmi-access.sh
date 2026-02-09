#!/bin/bash
# Get docker container ID for isvaconfig container
IVIACONFIG="$(kubectl get --no-headers=true pods -l app=iviaconfig -o custom-columns=:metadata.name)"

echo "Setting up tunnel to LMI on iviaconfig pod."
echo "Access LMI at https://localhost:9443"
echo "Quit this process to close tunnel."
kubectl port-forward ${IVIACONFIG} 9443
