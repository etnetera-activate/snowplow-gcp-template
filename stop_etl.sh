#!/bin/bash

# DEPRECATED - use orchestrator instead

source "./gcloud-config.sh"
gcloud config set project $GCP_NAME

# script stops all running dataflow and detele snowplow-load instance

# stop ETL and dataflow
# TODO: some loop until everything is closed
gcloud dataflow jobs drain --region $REGION `gcloud dataflow jobs list --region=$REGION | grep Running | tail -n 1 | cut -f 1 -d " "`
gcloud dataflow jobs drain --region $REGION `gcloud dataflow jobs list --region=$REGION | grep Running | head -n 1 | cut -f 1 -d " "`

gcloud --quiet compute instances delete orchestrator

#and check it
gcloud dataflow jobs list
gcloud compute instances list