#!/bin/bash

version=0.14.0
TEMP_BUCKET="%BUCKETNAME%"

sudo apt-get update
sudo apt-get -y install default-jre
sudo apt-get -y install unzip
wget https://dl.bintray.com/snowplow/snowplow-generic/snowplow_scala_stream_collector_google_pubsub_${version}.zip
gsutil cp ${TEMP_BUCKET}/config/collector.config .
unzip snowplow_scala_stream_collector_google_pubsub_${version}.zip
java -jar ./snowplow-stream-collector-google-pubsub-${version}.jar --config collector.config