#!/bin/bash
enrich_version="1.1.0"
bq_version="0.4.0"

source "gcloud-config.sh"

jobs=$(gcloud dataflow jobs list | grep "Running" | cut -d " " -f 1)
for job in $jobs
do
    echo "Stopping job: $job"
    gcloud dataflow jobs drain $job --region=europe-west1
done

echo "Killing java processes - mutator listener"
kill $(ps -ef | grep "java" | fgrep -v "grep java" | grep -v ps | awk '{print $2}')
