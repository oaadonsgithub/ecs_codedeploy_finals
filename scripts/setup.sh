#!/bin/bash

# Set the directory to run Terraform in (default: current directory)
TERRAFORM_DIR=${1:-.}

echo "Running 'terraform init' in $TERRAFORM_DIR..."

# Exit on any command failure
set -e

# Change to the specified directory
cd "$TERRAFORM_DIR"

#!/bin/bash

mkdir -p ~/.terraform.d

cat > ~/.terraform.d/credentials.tfrc.json <<EOF
{
  "credentials": {
    "app.terraform.io": {
      "token": "dzlRkFmj5bSwLg.atlasv1.szQWDuBE7Jj8Tv3KPUpQOceBlsPzAiEOwyyD2HVBQSlGZOaikKz3A02NcR9cLDEEIAY"
    }
  }
}
EOF


terraform login

# Initialize Terraform
terraform init

echo "Terraform initialization complete."