# Terraform

Terraform manages making a database, permissions, projects, buckets, networking, and kubernetes nodes. This does not manage kubernetes other than running a few scripts to set things up.

<https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform>

## Install

```
wget -nd https://releases.hashicorp.com/terraform/0.12.10/terraform_0.12.10_linux_amd64.zip
unzip terraform_0.12.10_linux_amd64.zip
which terraform
mv terraform /usr/local/bin/terraform
```

`brew install terraform` also works.

## Configure

Create `~/.terraformrc` and add the token from app.terraform.io

```
credentials "app.terraform.io" {
    token = ""
}
```

### GCP Authentication

In most cases, you will need to specify `google_credentials` in `terraform.tfvars`

Ex:

```
google_credentials = "serviceaccount-creds.json"
```
