#!/bin/bash
enrich_version="1.1.0"
bq_version="0.4.0"

source "gcloud-config.sh"

TEMP_BUCKET="gs://activate-equa-snowplow-test-1-temp"
project_id=$GCP_NAME
region=$REGION

echo "[info] Starting beam enricher dataflow"

#start beam enrich in data flow
./beam-enrich-$enrich_version/bin/beam-enrich \
    --runner=DataFlowRunner \
    --project=$project_id \
    --streaming=true \
    --job-name="beam-enrich" \
    --region=$region \
    --gcpTempLocation=$TEMP_BUCKET/temp-files \
    --raw=projects/$project_id/subscriptions/collected-good-sub \
    --enriched=projects/$project_id/topics/enriched-good \
    --bad=projects/$project_id/topics/enriched-bad \
    --pii=projects/$project_id/topics/enriched-pii \
    --resolver=iglu_config.json


echo "[info] Starting bigquery mutator and loader"

#create tables
./snowplow-bigquery-mutator-$bq_version/bin/snowplow-bigquery-mutator create \
    --config $(cat bigqueryloader_config.json | base64 -w 0) \
    --resolver $(cat iglu_config.json | base64 -w 0)

#listen to new bq types
./snowplow-bigquery-mutator-$bq_version/bin/snowplow-bigquery-mutator listen \
--config $(cat bigqueryloader_config.json | base64 -w 0) \
--resolver $(cat iglu_config.json | base64 -w 0) &

./snowplow-bigquery-loader-$bq_version/bin/snowplow-bigquery-loader \
    --config=$(cat bigqueryloader_config.json | base64 -w 0) \
    --resolver=$(cat iglu_config.json | base64 -w 0) \
    --runner=DataFlowRunner \
    --project=$project_id \
    --region=$region \
    --gcpTempLocation=${TEMP_BUCKET}/temp-files &

echo "[info] done. Wait for dataflow to be started"
