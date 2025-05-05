#!/usr/bin/env bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


# Set up an interrupt handler so we can exit gracefully
interrupt_count=0
interrupt_handler() {
  ((interrupt_count += 1))

  echo ""
  if [[ $interrupt_count -eq 1 ]]; then
    fail "Really quit? Hit ctrl-c again to confirm."
  else
    echo "Goodbye!"
    exit
  fi
}
trap interrupt_handler SIGINT SIGTERM

# This setup script does all the magic.

# Check for required tools
declare -a req_tools=("terraform" "sed" "curl" "jq")
for tool in "${req_tools[@]}"; do
  if ! command -v "$tool" > /dev/null; then
    fail "It looks like '${tool}' is not installed; please install it and run this setup script again."
    exit 1
  fi
done

# Get the minimum required version of Terraform
minimumTerraformMajorVersion=0
minimumTerraformMinorVersion=14
minimumTerraformVersion=$(($minimumTerraformMajorVersion * 1000 + $minimumTerraformMinorVersion))

# Get the current version of Terraform
installedTerraformMajorVersion=$(terraform version -json | jq -r '.terraform_version' | cut -d '.' -f 1)
installedTerraformMinorVersion=$(terraform version -json | jq -r '.terraform_version' | cut -d '.' -f 2)
installedTerraformVersion=$(($installedTerraformMajorVersion * 1000 + $installedTerraformMinorVersion))

# Check we meet the minimum required version
if [ $installedTerraformVersion -lt $minimumTerraformVersion ]; then
  echo
  fail "Terraform $minimumTerraformMajorVersion.$minimumTerraformMinorVersion.x or later is required for this setup script!"
  echo "You are currently running:"
  terraform version
  exit 1
fi






# Create a HCP Terraform organization
echo
echo "Creating an organization and workspace..."
sleep 1
setup() {
  curl https://$HOST/api/getting-started/setup \
    --request POST \
    --silent \
    --header "Content-Type: application/vnd.api+json" \
    --header "Authorization: Bearer $TOKEN" \
    --header "User-Agent: tfc-getting-started" \
    --data @- << REQUEST_BODY
{
	"workflow": "remote-operations",
  "terraform-version": "$TERRAFORM_VERSION"
}
REQUEST_BODY
}

response=$(setup)
err=$(echo $response | jq -r '.errors')

if [[ $err != null ]]; then
  err_msg=$(echo $err | jq -r '.[0].detail')
  if [[ $err_msg != null ]]; then
    fail "An error occurred: ${err_msg}"
  else 
    fail "An unknown error occurred: ${err}"
  fi
  exit 1
fi

# TODO: If there's an active trial, we should just retrieve that and configure
# it instead (especially if it has no state yet)
info=$(echo $response | jq -r '.info')
if [[ $info != null ]]; then
  info "\n${info}"
  exit 0
fi

organization_name=$(echo $response | jq -r '.data."organization-name"')
workspace_name=$(echo $response | jq -r '.data."workspace-name"')

echo
echo "Writing HCP Terraform configuration to backend.tf..."
sleep 2


echo
divider
echo
success "Ready to go; the example configuration is set up to use HCP Terraform!"

echo "You can view this workspace in the HCP Terraform UI here:"
echo "https://$HOST/app/${organization_name}/workspaces/${workspace_name}"
echo
info "Next, we'll run 'terraform init' to initialize the backend and providers:"
echo
echo "$ terraform init"
echo


echo
terraform init
echo
echo "..."
sleep 2

echo "$ terraform plan"


echo
terraform plan
echo
echo "..."
sleep 3
echo
divider
echo
success "The plan is complete!"

terraform apply -auto-approve

echo
echo "..."
sleep 3
echo
divider
echo
success "You did it! You just provisioned infrastructure with HCP Terraform!"
