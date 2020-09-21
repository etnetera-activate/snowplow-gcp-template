#!/bin/bash

# DEPRECATED - use orchestrator instead

source "gcloud-config.sh"

echo "PROJECT ID: $GCP_NAME"
gcloud config set project $GCP_NAME

gcloud compute instances create orchestrator \
    --machine-type=${ETL_MACHINE_TYPE}\
    --subnet=default --network-tier=PREMIUM \
    --metadata-from-file=startup-script=./configs/beam-and-bigqueryloader-startup.sh \
    --maintenance-policy=MIGRATE --service-account=${SERVICEACCOUNT} \
    --scopes=https://www.googleapis.com/auth/bigquery,https://www.googleapis.com/auth/pubsub,https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/devstorage.read_write \
    --tags=etl,http-server,https-server --image=${IMAGE} --image-project=${IMAGE_PROJECT} \
    --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=orchestrator

echo "[info] etl machine started. Wait until beam-enrich and bigquery_load starts dataflow. Cca. 5-10minutes"
echo "[test] gcloud dataflow jobs list"
echo "[test] gcloud compute instances list"
echo "[test] gcloud dataflow jobs list"
echo "[test] bq ls snowplow"
echo "[test] gcloud pubsub subscriptions pull --auto-ack enriched-good-sub-test"
echo "[test] bq query \"SELECT * from snowplow.pageviews LIMIT 100\""

echo "[warning] Running dataflow and ETL server will cost you cca. 15USD daily!"
echo "[warning] You can stop and delete it anytime using ./stop_etl.sh"
