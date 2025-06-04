#!/bin/bash

# This script moves the reserved public IPs to backup then in the default compartment.
COMPARTMENT_NAME="default"
COMPARTMENT_ID="ocid1.compartment.oc1..aaaaaaaacjhy3znpp43tzl3hymbyiwekyzhbyrazldvh3at26ax5ov34uj3a"
IP1_OCID="ocid1.publicip.oc1.sa-saopaulo-1.amaaaaaahzdyfvaaarpclyzybftohh6ak7apwvqn7utsebtfne62e7de67ya"
# IP2_OCID="ocid1.publicip.oc1.sa-saopaulo-1.amaaaaaahzdyfvaad6bazwn5fb5sxupo3dg3qokrhleabnb65ftij5tyitrq"

echo "Moving reserved public IPs to \"$COMPARTMENT_NAME\" compartment..."

oci network public-ip change-compartment --public-ip-id "$IP1_OCID" --compartment-id "$COMPARTMENT_ID"
# oci network public-ip change-compartment --public-ip-id "$IP2_OCID" --compartment-id "$COMPARTMENT_ID"

echo "Reserved public IPs moved to \"$COMPARTMENT_NAME\" compartment successfully."