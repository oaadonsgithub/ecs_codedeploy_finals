#!/bin/bash

# Set the directory to run Terraform in (default: current directory)
TERRAFORM_DIR=${1:-.}

echo "Running 'terraform init' in $TERRAFORM_DIR..."

# Exit on any command failure
set -e

# Change to the specified directory
cd "$TERRAFORM_DIR"


terraform login

# Initialize Terraform
terraform init

echo "Terraform initialization complete."