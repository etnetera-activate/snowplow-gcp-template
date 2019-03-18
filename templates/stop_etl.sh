#!/bin/bash

PROJECTID="%PROJECTID%"
gcloud config set project $PROJECTID

# script stops all running dataflow and detele snowplow-load instance

# stop ETL and dataflow
# TODO: some loop until everything is closed
gcloud dataflow jobs drain --region europe-west1 `gcloud dataflow jobs list | grep Running | tail -n 1 | cut -f 1 -d " "`
gcloud dataflow jobs drain --region europe-west1 `gcloud dataflow jobs list | grep Running | tail -n 1 | cut -f 1 -d " "`

gcloud --quiet compute instances delete snowplow-load

#and check it
gcloud dataflow jobs list
gcloud compute instances list