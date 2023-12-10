#!/bin/bash

subnet_range_cidr="${network_cidr_prefix}.0/24"

cd /data/dev/
export TAILSCALE_CLIENT_ID=$(cat /data/dev/config.json | jq -r .TAILSCALE_CLIENT_ID)
export TAILSCALE_CLIENT_SECRET=$(cat /data/dev/config.json | jq -r .TAILSCALE_CLIENT_SECRET)
sudo apt-get update
sudo apt install python3.11-venv -y

python3 -m venv env
source env/bin/activate
pip install requests

python3 get-tailscale-key.py

source /data/dev/tailscale-key.env

sudo tailscale up --accept-routes --advertise-routes $subnet_range_cidr --auth-key $tailnet_key

export hostname=$(hostname)

python3 authorise_routes.py