#!/bin/bash

COMPARTMENT_ID=$1
COMPARTMENT_NAME=$2

if [ -z "$COMPARTMENT_ID" ] || [ -z "$COMPARTMENT_NAME" ]; then
  echo "Usage: $0 <compartment_id> <compartment_name>"
  exit 1
fi


# This script moves the reserved public IPs to OKE-FREE compartment.
# COMPARTMENT_NAME="k8s"
# COMPARTMENT_ID=""

# Colocar aqui o OCID do Reserved Public IP
IP1_OCID="ocid1.publicip.oc1.sa-saopaulo-1.amaaaaaahzdyfvaaarpclyzybftohh6ak7apwvqn7utsebtfne62e7de67ya"
# IP2_OCID="ocid1.publicip.oc1.sa-saopaulo-1.amaaaaaahzdyfvaad6bazwn5fb5sxupo3dg3qokrhleabnb65ftij5tyitrq"

echo "Moving reserved public IPs to \"$COMPARTMENT_NAME\" compartment..."

oci network public-ip change-compartment --public-ip-id "$IP1_OCID" --compartment-id "$COMPARTMENT_ID"
# oci network public-ip change-compartment --public-ip-id "$IP2_OCID" --compartment-id "$COMPARTMENT_ID"

echo "Reserved public IPs moved to \"$COMPARTMENT_NAME\" compartment successfully."


