#!/bin/bash
## 11/2024 ##

# delete registry and repo when done.
## when not careful azure will wipe repository once empty. Ensure you check if az cli still functions the same before running.

## CHANGE ME
REGISTRY_NAME="REGISTRY-NAME"
## CHANGE ME
REPOSITORY_NAME="REPO-NAME" 
## CHANGE ME
CUTOFF_DATE="2024-11-8T00:00:00Z"


echo "Fetching manifests from repository '$REPOSITORY_NAME' in registry '$REGISTRY_NAME'..."
manifests=$(az acr repository show-manifests \
  --name $REGISTRY_NAME \
  --repository $REPOSITORY_NAME \
  --orderby time_asc \
  --output json)

# check if any manifests were retrieved
if [[ -z "$manifests" || "$manifests" == "[]" ]]; then
  echo "No manifests found in repository '$REPOSITORY_NAME'. Exiting."
  exit 0
fi

# iterate through manifests and delete old ones
echo "Processing manifests..."
echo "$manifests" | jq -c '.[]' | while read manifest; do
  # Extract timestamp and digest
  timestamp=$(echo $manifest | jq -r '.timestamp')
  digest=$(echo $manifest | jq -r '.digest')

  # ensure timestamp and digest are valid
  if [[ -z "$timestamp" || -z "$digest" ]]; then
    echo "Skipping manifest due to missing fields."
    continue
  fi

  # display the manifest details being processed
  echo "Processing manifest with digest: $digest"
  echo "Timestamp: $timestamp"

  # compare the timestamp with the cutoff date..
  if [[ "$timestamp" < "$CUTOFF_DATE" ]]; then
    echo "Deleting image with digest: $digest (Timestamp: $timestamp)..."
    az acr repository delete \
      --name $REGISTRY_NAME \
      --image "$REPOSITORY_NAME@$digest" \
      --yes || echo "Failed to delete image $REPOSITORY_NAME@$digest"
    echo "Successfully deleted image: $REPOSITORY_NAME@$digest"
  else
    echo "Manifest $digest is newer than cutoff date ($CUTOFF_DATE). Skipping."
  fi

  echo "-----------------------------------"
done

echo "Processing complete."