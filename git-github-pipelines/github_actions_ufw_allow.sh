#!/bin/bash

# gitHub Meta API URL
GITHUB_META_URL="https://api.github.com/meta"

# temp file to store GitHub IPs
TEMP_FILE="/tmp/github_ips.txt"

# UFW rule comment identifier
UFW_COMMENT="GitHub SSH Allow"

# fetch GitHub IP ranges and extract SSH-related IPs (adjust for your use case)
echo "Fetching GitHub IP ranges..."
curl -s $GITHUB_META_URL | jq -r '.ssh_keys[], .hooks[]?, .pages[]?, .actions[]?' > $TEMP_FILE

# Verify that the IP list isn't empty or invalid
if [ ! -s $TEMP_FILE ]; then
    echo "Failed to fetch GitHub IP ranges or no valid IPs returned."
    exit 1
fi

# remove existing UFW rules with the specific comment
#echo "Removing existing UFW rules for GitHub SSH..."
#sudo ufw status numbered | grep "$UFW_COMMENT" | awk '{print $1}' | sort -r | xargs -I {} sudo ufw delete {}

#echo "Rmoving existing UFW rules for GitHub SSH..."
#sudo ufw status | grep "$UFW_COMMENT" | while read -r line; do
#    # Extract the rule description
#    rule=$(echo "$line" | sed -e 's/\[[0-9]*\] //')
#    # Delete the rule using its description
#    sudo ufw delete "$rule"
#done

# add new UFW rules for each valid IP range
echo "Adding new UFW rules for GitHub SSH..."
while IFS= read -r ip; do
    if [[ $ip =~ ^[0-9a-fA-F:.]+/[0-9]+$ ]]; then  # Validates IP format (IPv4/IPv6 CIDR)
        sudo ufw allow from "$ip" to any port 22 proto tcp comment "$UFW_COMMENT"
    else
        echo "Skipping invalid IP: $ip"
    fi
done < $TEMP_FILE

# Clean up!
rm -f $TEMP_FILE

echo "UFW rules updated successfully."