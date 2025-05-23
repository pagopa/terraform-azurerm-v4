#!/bin/bash

set -e

action=$1
shift 1
other=$@

subscription="DevOpsLab"

case $action in
    "init" | "apply" | "plan" | "destroy" | "console")
        # shellcheck source=/dev/null
        if [ -e "./backend.ini" ]; then
          source ./backend.ini
        else
          echo "Error: no backend.ini found!"
          exit 1
        fi

        az account set -s "${subscription}"
        export ARM_SUBSCRIPTION_ID=$(az account list --query "[?isDefault].id" --output tsv)

        terraform init
        terraform "$action" $other
        ;;
    "clean" )
        rm -rf .terraform* terraform.tfstate*
        echo "cleaned..."
        ;;
    * )
        echo "Missed action: init, apply, plan, destroy clean"
        exit 1
        ;;
esac
