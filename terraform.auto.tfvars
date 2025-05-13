// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0

vpc_id     = "vpc-095cdd66f238bf25a"
subnet_ids = ["subnet-0c7b24345606db1bf", "subnet-08171a92d5bb8b6fd"]
ami_id     = "ami-0c12f1613ee864d3f"
key_name   = "MyNodeApplication"
certificate_arn = "arn:aws:acm:us-west-1:537124950459:certificate/3474ac38-eab9-4641-958c-0d388bac0f64"
aws_account_id = "537124950459"
aws_account_region = "us-west-1"
lb_target_group_443_name = "webtg"
region = "us-west-1"
image_uri       = "537124950459.dkr.ecr.us-west-1.amazonaws.com/karrio:latest"
sns_alert_email = "oaaderibigbe@dons.usfca.edu"
ECR_REPO = "537124950459.dkr.ecr.us-west-1.amazonaws.com/karrio:latest"
ECR_REPO_A = "537124950459.dkr.ecr.us-west-1.amazonaws.com/karrio_archive:latest"
domain_name = "karrio.ianthony.com"


