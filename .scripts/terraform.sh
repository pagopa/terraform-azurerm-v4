#!/bin/bash

#
# Usage of the Terraform script:
#
# This script simplifies the execution of common Terraform commands for managing Azure infrastructure.
#
# Pre-conditions:
# 1. Terraform CLI installed and configured on the system.
# 2. Azure CLI (az) installed and configured with a valid Azure account.
# 3. A file named `backend.ini` must exist in the same directory as the script.
#    This file should contain a line defining the Azure subscription name as `subscription`.
#    Example `backend.ini` file content:
#    ```
#    subscription=YourAzureSubscriptionName
#    ```
# 4. (Optional) Additional backend configurations can be included in `backend.ini`.
#
# Execution:
# Execute the script with one of the following actions as the first argument:
#   - init: Initializes the Terraform working directory (downloads providers, configures backend).
#   - plan: Generates an execution plan, showing the changes that will be applied to the infrastructure.
#   - apply: Applies the changes to the infrastructure defined in the plan.
#   - destroy: Destroys the resources managed by Terraform.
#   - clean: Removes the Terraform cache and state file (terraform.tfstate*).
#
# You can pass additional options to Terraform after the main action.
# Example: ./terraform_script.sh apply -auto-approve
#

set -euo pipefail

ACTION="$1"
shift
OTHER_ARGS="$@"

# Variable for the Azure subscription name.
SUBSCRIPTION_NAME=""

# Variable for the Azure subscription ID.
SUBSCRIPTION_ID=""

# Variable to indicate if the backend environment has been configured.
BACKEND_CONFIGURED=false

# Function to display an error message and exit.
error_exit() {
  echo "Error: $1" >&2
  exit 1
}

# Function to load the subscription name from the 'backend.ini' file.
load_subscription_name() {
  if [ -e "./backend.ini" ]; then
    # shellcheck source=/dev/null
    source ./backend.ini
    if [ -z "$subscription" ]; then
      error_exit "The 'subscription' variable is not defined in the 'backend.ini' file."
    fi
    SUBSCRIPTION_NAME="$subscription"
    echo "Subscription name loaded from 'backend.ini': $SUBSCRIPTION_NAME"
  else
    error_exit "The 'backend.ini' file was not found. This file is required to define the Azure subscription name."
  fi
}

# Function to get the subscription ID given the name.
get_subscription_id() {
  load_subscription_name
  SUBSCRIPTION_ID=$(az account list --query "[?name=='$SUBSCRIPTION_NAME'].id" --output tsv)
  if [ -z "$SUBSCRIPTION_ID" ]; then
    error_exit "Unable to find a subscription with the name: '$SUBSCRIPTION_NAME'."
  fi
  echo "Found subscription ID: $SUBSCRIPTION_ID for name: $SUBSCRIPTION_NAME"
}

# Function to initialize Terraform.
terraform_init() {
  get_subscription_id

  if [ -e "./backend.ini" ]; then
    # shellcheck source=/dev/null
    source ./backend.ini
    BACKEND_CONFIGURED=true
    echo "Backend configuration loaded from backend.ini"
  else
    echo "Warning: backend.ini not found. Assuming default backend configuration or environment variables."
  fi

  # Set the Azure account and export the subscription ID for Terraform.
  az account set --subscription "$SUBSCRIPTION_ID"
  export ARM_SUBSCRIPTION_ID="$SUBSCRIPTION_ID"

  terraform init -backend-config="subscription_id=$SUBSCRIPTION_ID"
}

# Function to execute Terraform commands (apply, plan, destroy).
terraform_execute() {
  get_subscription_id

  if [ "$BACKEND_CONFIGURED" = false ]; then
    terraform_init
  fi

  # Set the Azure account and export the subscription ID for Terraform.
  az account set --subscription "$SUBSCRIPTION_ID"
  export ARM_SUBSCRIPTION_ID="$SUBSCRIPTION_ID"

  terraform "$ACTION" ${OTHER_ARGS}
}

case "$ACTION" in
  "init")
    terraform_init
    ;;
  "apply")
    terraform_execute
    ;;
  "plan")
    terraform_execute
    ;;
  "destroy")
    terraform_execute
    ;;
  "clean")
    rm -rf .terraform* terraform.tfstate*
    echo "Terraform state and cache cleaned."
    ;;
  *)
    echo "Usage: $0 {init|apply|plan|destroy|clean} [terraform_options...]"
    exit 1
    ;;
esac

echo "Terraform action '$ACTION' completed."
