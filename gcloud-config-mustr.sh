#!/bin/bash

# edit and rename to gcloud-config.sh
# then run ./gcloud-init-project.sh

### CONFIG ###########################################################
export GCP_NAME="snowplow-test-1"
export SERVICEACCOUNT="sn-service@xxxx.iam.gserviceaccount.com"

# region must be have dafaflow endpoint
# https://cloud.google.com/dataflow/docs/concepts/regional-endpoints
export ZONE="europe-west1-a"
export REGION="europe-west1"           

export COLLECTOR_MACHINE_TYPE="e2-micro"
export ETL_MACHINE_TYPE="e2-small"
export IMAGE="debian-9-stretch-v20190312"   # debian 9 has default JRE8. ApacheBeam don't support higher JRE
export IMAGE_PROJECT="debian-cloud"

######################################################################

export GS_BUCKET_PREFIX=$GCP_NAME
export TEMP_BUCKET="gs://${GS_BUCKET_PREFIX}-temp"

######################################################################
