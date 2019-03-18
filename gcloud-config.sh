#!/bin/bash 

### CONFIG ###########################################################

GCP_NAME="my-snowplow-demo"
ZONE="europe-west3-a"
REGION="europe-west3"
SERVICEACCOUNT="xxxxxxx-compute@developer.gserviceaccount.com"

######################################################################

UUID=$(uuidgen)
GS_BUCKET_PREFIX=$GCP_NAME
TEMP_BUCKET="gs://${GS_BUCKET_PREFIX}-temp"

gcloud config set project $GCP_NAME

#prepare config files from template

mkdir ./configs
cd ./templates/

for file in `ls ./*.*`
do
    echo "Procesing template ${file}"
    cat $file | sed -e "s/%REGION%/${REGION}/g"  -e "s/%BUCKETNAME%/${TEMP_BUCKET_ESC}/g"  -e "s/%PROJECTID%/${GCP_NAME}/g" | \
    sed -e "s/%UUID%/${UUID}/g" -e "s/%SERVICEACCOUNT%/${SERVICEACCOUNT}/g"\
    > ../configs/$file
done
cd ..
mv ./configs/start_etl.sh .
mv ./configs/stop_etl.sh .


exit

#collector pubsub
gcloud alpha pubsub topics create good
gcloud alpha pubsub topics create bad
gcloud pubsub subscriptions create "good-sub" --topic="good"
gcloud pubsub subscriptions create "bad-sub" --topic="bad"

#enriched pubsub
gcloud alpha pubsub topics create enriched-bad
gcloud alpha pubsub topics create enriched-good
gcloud alpha pubsub topics create enriched-pii

gcloud pubsub subscriptions create "enriched-good-sub" --topic="enriched-good"
gcloud pubsub subscriptions create "enriched-bad-sub" --topic="enriched-bad"
gcloud pubsub subscriptions create "enriched-pii-sub" --topic="enriched-pii"

#bigquery
gcloud alpha pubsub topics create bq-bad-rows
gcloud alpha pubsub topics create bq-failed-inserts
gcloud alpha pubsub topics create bq-types

gcloud pubsub subscriptions create "bq-types-sub" --topic="bq-types"
gcloud pubsub subscriptions create "bq-bad-rows-sub" --topic="bq-bad-rows"
gcloud pubsub subscriptions create "bq-failed-inserts" --topic="bq-failed-inserts"


#prepare temp buckets for configurations
gsutil mb -l EU "$TEMP_BUCKET"
touch zero.txt
gsutil cp ./zero.txt  $TEMP_BUCKET/temp-files/
gsutil cp ./zero.txt  $TEMP_BUCKET/config/
rm ./zero.txt

gsutil cp ./configs/iglu_config.json $TEMP_BUCKET/config/
gsutil cp ./configs/collector.config $TEMP_BUCKET/config/
gsutil cp ./configs/enrich.config $TEMP_BUCKET/config/
gsutil cp ./configs/bigqueryloader_config.json $TEMP_BUCKET/config/

#prepare BigQuery
bq --location=EU mk "$GCP_NAME:snowplow"

###################################### Colector group + loadbalancer ###################################################
# collector instances template
gcloud compute instance-templates create snowplow-collector-template \
    --machine-type=f1-micro \
    --network=projects/activate-snowplow-demo/global/networks/default \
    --network-tier=PREMIUM \
    --metadata-from-file=startup-script=./configs/collector_startup.sh \
    --maintenance-policy=MIGRATE --service-account=$SERVICEACCOUNT \
    --scopes=https://www.googleapis.com/auth/pubsub,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/devstorage.read_only \
    --tags=collector,http-server,https-server \
    --image=debian-9-stretch-v20190312 \
    --image-project=debian-cloud \
    --boot-disk-size=10GB \
    --boot-disk-type=pd-standard \
    --boot-disk-device-name=snowplow-collector-template

gcloud compute firewall-rules create snowplow-collector-rule --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:8080 --source-ranges=0.0.0.0/0 --target-tags=collector

gcloud compute health-checks create http "snowplow-collector-health-check" --timeout "5" --check-interval "10" --unhealthy-threshold "3" --healthy-threshold "2" --port "8080" --request-path "/health"

gcloud beta compute instance-groups managed create snowplow-collector-group --base-instance-name=snowplow-collector-group --template=snowplow-collector-template --size=1  --health-check=snowplow-collector-health-check --initial-delay=300

gcloud compute instance-groups managed set-autoscaling "snowplow-collector-group" --cool-down-period "60" --max-num-replicas "2" --min-num-replicas "1" --target-cpu-utilization "0.6"

gcloud compute instances list

####################################################################################################
# MANUAL ACTIONS
# now configure firewall. Backend service id this group and health
####################################################################################################

echo "Done - now setup firewall with snowplow-collector-group as a backend service and snowplow-collector-health-check"
echo "https://www.simoahava.com/analytics/install-snowplow-on-the-google-cloud-platform/#step-3-create-a-load-balancer"
echo
echo "Then run ./start_etl.sh and don't forget to stop it soon ;-)"