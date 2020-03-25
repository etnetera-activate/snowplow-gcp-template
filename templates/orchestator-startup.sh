#!/bin/bash
enrich_version="1.1.0"
bq_version="0.4.0"
TEMP_BUCKET="%TEMPBUCKET%"
project_id="%PROJECTID%"
region="%REGION%"

sudo apt-get update
sudo apt-get -y install default-jre
sudo apt-get -y install unzip
sudo apt-get -y install less wget

mkdir /srv/snowplow
cd /srv/snowplow

wget https://dl.bintray.com/snowplow/snowplow-generic/snowplow_beam_enrich_$enrich_version.zip
unzip snowplow_beam_enrich_$enrich_version.zip

wget https://dl.bintray.com/snowplow/snowplow-generic/snowplow_bigquery_loader_$bq_version.zip
unzip snowplow_bigquery_loader_$bq_version.zip

wget https://dl.bintray.com/snowplow/snowplow-generic/snowplow_bigquery_mutator_$bq_version.zip
unzip snowplow_bigquery_mutator_$bq_version.zip

gsutil cp  ${TEMP_BUCKET}/config/iglu_config.json .
gsutil cp  ${TEMP_BUCKET}/config/bigqueryloader_config.json .

gsutil cp  ${TEMP_BUCKET}/orchestrator/start-dataflows.sh .
gsutil cp  ${TEMP_BUCKET}/orchestrator/stop-dataflows.sh .
gsutil cp  ${TEMP_BUCKET}/orchestrator/gcloud-config.sh .

chmod +x ./*dataflows.sh

