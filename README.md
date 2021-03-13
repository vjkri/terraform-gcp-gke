# GKE terraform

This module handles  Google Cloud Platform Kubernetes Engine cluster creation and configuration with Node Pools, IP MASQ, Network Policy, etc. The resources/services/activations/deletions that this module will create/trigger are:

Create a GKE cluster with the provided addons
Create GKE Node Pool(s) with provided configuration and attach to cluster
Verify through kitchen-terraform

## Prerequisites

Check that Terraform is installed and up to date on your machine with `terraform version`.
At the time of writing the version of binary distributed by HashiCorp is `v0.11.13`.
Installation instructions can be found [here](https://learn.hashicorp.com/terraform/getting-started/install.html).

This guide uses the Google Cloud Platform (GCP) utility `gcloud`, which is part of the [Cloud SDK](https://cloud.google.com/sdk/).
Installation instructions for this can be found [here](https://cloud.google.com/sdk/install).
The Google Cloud Storage (GCS) command line utility `gsutil` is also used to create and delete Buckets.
It is installed as part of the Cloud SDK.
Much of what these commands go can be achieved using the GCP Console, but using the commands allows the guide to be concise and precise about what to do.

## Setup

The following guide assumes commands are run from the `example` directory.

Provide the input variables with a `terraform.tfvars` file provided under test/fixtures/tf_module:

```
terraform.tfvars
```

Update the below to reflect your public ip, so that you can connect to master

```

master_authorized_networks_cidr_blocks = [
  {
    cidr_block = "90.221.77.132/32"
    display_name = "default"
  },  
]
```
The values set in this file should be edited according to your environment and requirements.

Once the Cloud SDK is installed you can authenticating, set the project, and choose a compute zone with the interactive command:

```
gcloud init
```

Ensure the required APIs are enabled:

```
gcloud services enable storage-api.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable iam.googleapis.com
```

Now create a service account for Terraform to use, generate a key file for it, and save the key location as an environment variable:

```
gcloud iam service-accounts create terraform
gcloud projects add-iam-policy-binding [PROJECT_ID] --member "serviceAccount:terraform@[PROJECT_ID].iam.gserviceaccount.com" --role "roles/owner"
gcloud iam service-accounts keys create key.json --iam-account terraform@[PROJECT_ID].iam.gserviceaccount.com
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/key.json"
```

**NOTE: Keep the key file in a safe place, and do not share or publicise it.**

Next create a GCS Bucket that will be used to hold Terraform state information.
The Bucket name must be globally unique, a suggested name is `[PROJECT_ID]-terraform-state`:

```
gsutil mb gs://[BUCKET_NAME]
```

Next, initialise Terraform with the name of the GCS Bucket just created:

```
terraform init -backend-config=bucket=[BUCKET_NAME] -backend-config=project=[GOOGLE_PROJECT]
```

### Install Kitchen-terraform

```
bundle install
```


### List

```
bundle exec kitchen list
```
### Now that kitchen-terraform is setup check that the configuration is valid, If the configuration is valid then apply it and also verify with:

```
bundle exec kitchen converge
```

### Verify

```
bundle exec kitchen verify
```

### To test end to end

```
bundle exec kitchen test
```

### Clean Up

Remove the infrastructure created by Terraform with:

```
bundle exec kitchen destroy
```

Sometimes Terraform may report a failure to destroy some resources due to dependencies and timing contention.
In this case wait a few seconfds and run the above command again.
If it is still unable to remove everything it may be necessary to remove resources manually using the `gcloud` command or the Cloud Console.

The GCS Bucket used for Terraform state storage can be removed with:

```
gsutil rm -r gs:[BUCKET_NAME]
```
