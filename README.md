# Template for semi-automatic Snowplow deployment to Google Cloud

This repo contains semi automatic tools for instaling snowplow to GoogleCloudPlatform. It automated tasks from a great tutorial from Simo Ahava
https://www.simoahava.com/analytics/install-snowplow-on-the-google-cloud-platform/

You should read Simo's article first to get some overview about whole Snowplow GCP ecosystem. All scripts have been tested on Debian runing in Windows 10 Linux Subsystem.

## Prepare
First make some steps from tutorial.

1. Prepare Google Cloud Project and enable billing. Remember *project-id*
2. Enable apis *PUB/SUB*, *Compute*, *Dataflow*
3. Create service account, download auth.json and remember service *service-acount-email*
   
Following steps are optional. You can skip them if you already use gcloud command line tools.
4. Install gcloud (https://cloud.google.com/sdk/docs/#deb)
5. Init gcloud command line. Run `gcloud init`
6. Init bigquery commad line. Run `bq init`

## Install this template

Get template from git 
```
git clone https://github.com/etnetera-activate/snowplow-gcp-template.git
cd snowplow-gcp-template
```

Run `./install.sh` for instaling package for generating UUID and jq JSON parser

## Use this template

Edit `./gcloud-config.sh` . Replace PRIJECTID, SERVICEACCOUNT and you can change ZONE and REGION if you wish.

Then run `./gcloud-config.sh`. This script will:

1. Prepare some config files and start/stop script for ETL.
2. Create all pubsub topics and subscribers
3. Create storage bucket and copy config files
4. Create big query dataset
5. Create instance template for collector and create collector group

Until script finish you should manually configure firewall. 

## START / STOP ETL
The ETL process is quite expensive as is utilize Google Dataflow. You should start in only for short time and then kill it.

Simple use `./start_etl.sh` and `./stop_etl.sh` for this purpose.

`./start_etl.sh` creates new virtual machine, which runs bigquery mutator and which starts two dataflows (one for enrich and second for bigquery inserts). 
After you run it you can check running instances using:

`gcloud compute instances list`

After some time, you should see:

* snowplow-collector-xxx instance (one or more depending on group autoscale settings)
* snowplow-etl
* some machine started for beam dataflow 
* some machine started for load dataflow

You can anso check dataflows using

`gcloud dataflow jobs list`

There should be two running dataflows.

`./stop_etl.sh` stops both dataflow and delete the ETL instance. After some time there will be only the collector machines and nothing more.




