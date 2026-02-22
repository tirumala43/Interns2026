#!/bin/bash

# Variables
RESOURCE_GROUP="gummatirumalarao-rg"
TEMPLATE_FILE="multi-os-arm.json"
PARAMS_FILE="multi-os-parameters.json"
DEPLOYMENT_NAME="multi-os-deployment"

echo "Starting deployment: $DEPLOYMENT_NAME in resource group: $RESOURCE_GROUP"
echo "Template: $TEMPLATE_FILE"
echo "Parameters: $PARAMS_FILE"
echo "-------------------------------------------------"

# Start deployment with verbose output
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --name $DEPLOYMENT_NAME \
  --template-file $TEMPLATE_FILE \
  --parameters @$PARAMS_FILE \
  --verbose

echo "-------------------------------------------------"
echo "Deployment finished. Checking resource status..."

# Fetch all deployment operations
RESOURCES=$(az deployment operation group list \
  --resource-group $RESOURCE_GROUP \
  --name $DEPLOYMENT_NAME \
  --query "[].{Name:properties.targetResource.resourceName, Type:properties.targetResource.resourceType, Status:properties.provisioningState}" \
  -o tsv)

# Loop through each resource to show status
echo "Resource Status Summary:"
while IFS=$'\t' read -r name type status; do
    if [ "$status" == "Succeeded" ]; then
        echo "Resource: $name ($type) - Created Successfully"
    elif [ "$status" == "Failed" ]; then
        echo "Resource: $name ($type) - FAILED"
        # Print detailed error
        az deployment operation group list \
          --resource-group $RESOURCE_GROUP \
          --name $DEPLOYMENT_NAME \
          --query "[?properties.targetResource.resourceName=='$name'].properties.statusMessage" \
          -o tsv
    else
        echo "Resource: $name ($type) - Status: $status"
    fi
done <<< "$RESOURCES"

# Check overall deployment status
OVERALL_STATUS=$(az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name $DEPLOYMENT_NAME \
  --query "properties.provisioningState" -o tsv)

echo "-------------------------------------------------"
echo "Overall Deployment Status: $OVERALL_STATUS"

if [ "$OVERALL_STATUS" != "Succeeded" ]; then
    echo "Deployment had errors. Please check above details."
    exit 1
fi

echo "Deployment completed successfully."