# Overview

This demonstrates deploying app code to a Function App. The Azure infrastructure is created using Terraform.

## Requirements

- An Azure subscription
- Terraform 0.12.x installed

## Usage

Deploy the Azure infrastructure and app code using the `deploy.sh` script. This will redeploy the app code to the function when changes are made to the app code. For example change the log statement: `log.Println("Timer trigger was invoked: Version 1")` to something else and rerun `deploy.sh`.
