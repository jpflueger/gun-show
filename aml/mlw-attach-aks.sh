#!/bin/bash

MLW_NAME=""
MLWAKS_NAME=""
RG_NAME=""
AKS_ID=""

FORCE_REATTACH=false

while getopts ":w:c:g:a:f" arg; do
  case "${arg}" in
    w)
      if [[ -z "$OPTARG" || $OPTARG =~ ^-.* ]]; then
        echo "Error: missing argument for -${arg} option"
        exit 1
      fi
      MLW_NAME="${OPTARG}"
      ;;
    c)
      if [[ -z "$OPTARG" || $OPTARG =~ ^-.* ]]; then
        echo "Error: missing argument for -${arg} option"
        exit 1
      fi
      MLWAKS_NAME="${OPTARG}"
      ;;
    g)
      if [[ -z "$OPTARG" || $OPTARG =~ ^-.* ]]; then
        echo "Error: missing argument for -${arg} option"
        exit 1
      fi
      RG_NAME="${OPTARG}"
      ;;
    a)
      if [[ -z "$OPTARG" || $OPTARG =~ ^-.* ]]; then
        echo "Error: missing argument for -${arg} option"
        exit 1
      fi
      if [[ ! $(tr "[:upper:]" "[:lower:]" <<<${OPTARG}) =~ ^/subscriptions/.+/resourcegroups/.+/providers/microsoft.containerservice/managedclusters/.+$ ]]; then
        echo "Error: -a option is not a valid AKS Resource Identifier => $OPTARG"
        exit 1
      fi
      AKS_ID="${OPTARG}"
      ;;
    f)
      FORCE_REATTACH=true
      ;;
    :)
      echo "Error: -${OPTARG} requires an argument."
      exit 1
      ;;
    \?)
      echo "Invalid option: -${OPTARG}."
      exit 1
      ;;
  esac
done

if [[ -z "$MLW_NAME" ]]; then
  echo "Error: -w (workspace name) is a required parameter"
  exit 1
fi

if [[ -z "$MLWAKS_NAME" ]]; then
  echo "Error: -c (compute name) is a required parameter"
  exit 1
fi

if [[ -z "$RG_NAME" ]]; then
  echo "Error: -g (resource group name) is a required parameter"
  exit 1
fi

if [[ -z "$AKS_ID" ]]; then
  echo "Error: -a (aks resource id) is a required parameter"
  exit 1
fi

PROVISIONING_STATE=$(az ml computetarget show \
  --name $MLWAKS_NAME \
  --workspace-name $MLW_NAME \
  --resource-group $RG_NAME \
  --query provisioningState \
  --output tsv)

echo "Provisioning state: $PROVISIONING_STATE"

if [[ $PROVISIONING_STATE == "Creating" ]]; then
  echo "Skipping attachment, compute target still attaching"
  exit 0
elif [[ $PROVISIONING_STATE == "Succeeded" ]]; then
  if $FORCE_REATTACH; then
      echo "Forcing re-attachment of compute target"
      az ml computetarget detach \
        --name $MLWAKS_NAME \
        --resource-group $RG_NAME \
        --workspace-name $MLW_NAME
  else
    echo "Skipping attachment, compute target already attached"
    exit 0
  fi
else
  echo "Unrecognized provisioning state, aborting"
  exit 1
fi

az ml computetarget attach aks \
  --compute-resource-id $AKS_ID \
  --name $MLWAKS_NAME \
  --resource-group $RG_NAME \
  --workspace-name $MLW_NAME
