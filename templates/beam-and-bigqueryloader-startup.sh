#!/bin/bash
export enrich_version="1.1.0"
export bq_version="0.4.0"

# Values should be updated manually
export project_id="xxxx-yyyy-1234"
export TEMP_BUCKET=gs://$project_id-temp
export region="europe-west1"
export service_account=test-service-account@xxxx-yyyy-1234.iam.gserviceaccount.com

sudo apt-get update
sudo apt-get -y install default-jre
sudo apt-get -y install unzip
sudo apt-get -y install less wget


wget https://dl.bintray.com/snowplow/snowplow-generic/snowplow_beam_enrich_$enrich_version.zip
unzip snowplow_beam_enrich_$enrich_version.zip

wget https://dl.bintray.com/snowplow/snowplow-generic/snowplow_bigquery_loader_$bq_version.zip
unzip snowplow_bigquery_loader_$bq_version.zip

wget https://dl.bintray.com/snowplow/snowplow-generic/snowplow_bigquery_mutator_$bq_version.zip
unzip snowplow_bigquery_mutator_$bq_version.zip

gsutil cp  ${TEMP_BUCKET}/config/iglu_config.json .
gsutil cp  ${TEMP_BUCKET}/config/bigqueryloader_config.json .

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
    --resolver=iglu_config.json \
    --serviceAccount=$service_account

#create tables
./snowplow-bigquery-mutator-$bq_version/bin/snowplow-bigquery-mutator create --config $(cat bigqueryloader_config.json | base64 -w 0) --resolver $(cat iglu_config.json | base64 -w 0)

#listen to new bq types
./snowplow-bigquery-mutator-$bq_version/bin/snowplow-bigquery-mutator listen --config $(cat bigqueryloader_config.json | base64 -w 0) --resolver $(cat iglu_config.json | base64 -w 0) &

./snowplow-bigquery-loader-$bq_version/bin/snowplow-bigquery-loader --config=$(cat bigqueryloader_config.json | base64 -w 0) --resolver=$(cat iglu_config.json | base64 -w 0) --runner=DataFlowRunner --project=$project_id --region=$region --gcpTempLocation=${TEMP_BUCKET}/temp-files
