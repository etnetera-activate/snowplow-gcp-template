#!/bin/bash

# create new instance of orchestarator whic can start / stop dataflow jobs

source "gcloud-config.sh"

echo "PROJECT ID: $GCP_NAME"
gcloud config set project $GCP_NAME

gsutil cp ./orchestrator-init/start-dataflows.sh $TEMP_BUCKET/orchestrator/
gsutil cp ./orchestrator-init/stop-dataflows.sh $TEMP_BUCKET/orchestrator/
gsutil cp ./gcloud-config.sh $TEMP_BUCKET/orchestrator/


gcloud compute instances create orchestrator \
    --machine-type=${ETL_MACHINE_TYPE}\
    --subnet=default --network-tier=PREMIUM \
    --metadata-from-file=startup-script=./configs/orchestator-startup.sh \
    --maintenance-policy=MIGRATE --service-account=${SERVICEACCOUNT} \
    --scopes=https://www.googleapis.com/auth/bigquery,https://www.googleapis.com/auth/pubsub,https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/devstorage.read_write \
    --tags=etl,http-server,https-server --image=${IMAGE} --image-project=${IMAGE_PROJECT} \
    --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=orchestrator

echo "[info] Ready."
echo "[test] gcloud compute ssh orchestator"
echo "[test] cd /srv/snowplow"