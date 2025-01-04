#!/bin/bash

# paths to Cloudflare IP lists
IPV4_URL="https://www.cloudflare.com/ips-v4"
IPV6_URL="https://www.cloudflare.com/ips-v6"

# temp files to store downloaded IP lists
TEMP_IPV4="/tmp/cloudflare_ipv4.txt"
TEMP_IPV6="/tmp/cloudflare_ipv6.txt"

# fetch the latest CF IP lists
echo "Fetching Cloudflare IP lists..."
curl -s $IPV4_URL -o $TEMP_IPV4
curl -s $IPV6_URL -o $TEMP_IPV6

# define UFW rule comments to identify CF IPs
UFW_TAG="cloudflare-allow"

# remove old Cloudflare rules
echo "Removing old Cloudflare UFW rules..."
sudo ufw status numbered | grep "$UFW_TAG" | awk '{print $1}' | sort -r | xargs -I {} sudo ufw delete {}

# add new Cloudflare IPv4 rules for ports 80 and 443
echo "Adding new Cloudflare IPv4 rules for ports 80 and 443..."
while IFS= read -r ip; do
    sudo ufw allow proto tcp from "$ip" to any port 80,443 comment "$UFW_TAG (IPv4)"
done < "$TEMP_IPV4"

# add new Cloudflare IPv6 rules for ports 80 and 443
echo "Adding new Cloudflare IPv6 rules for ports 80 and 443..."
while IFS= read -r ip; do
    sudo ufw allow proto tcp from "$ip" to any port 80,443 comment "$UFW_TAG (IPv6)"
done < "$TEMP_IPV6"

# cean up temp files
echo "Cleaning up temporary files..."
rm -f "$TEMP_IPV4" "$TEMP_IPV6"

# reload UFW to apply changes
echo "Reloading UFW..."
sudo ufw reload

echo "Cloudflare IP update complete."

echo "cross your fingers"