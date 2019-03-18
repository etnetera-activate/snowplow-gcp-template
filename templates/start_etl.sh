#!/bin/bash

SERVICEACCOUNT="%SERVICEACCOUNT%"
PROJECTID="%PROJECTID%"

gcloud config set project $PROJECTID

gcloud compute instances create snowplow-load \
    --machine-type=f1-micro \
    --subnet=default --network-tier=PREMIUM \
    --metadata-from-file=startup-script=./configs/beam-and-bigqueryloader-startup.sh \
    --maintenance-policy=MIGRATE --service-account=${SERVICEACCOUNT} \
    --scopes=https://www.googleapis.com/auth/bigquery,https://www.googleapis.com/auth/pubsub,https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/devstorage.read_write \
    --tags=etl,http-server,https-server --image=debian-9-stretch-v20190312 --image-project=debian-cloud \
    --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=snowplow-load

