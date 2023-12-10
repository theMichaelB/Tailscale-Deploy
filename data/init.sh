#!/bin/bash

subnet_range_cidr="192.168.10.0/24"

sudo apt-get update
sudo apt install python3.11-venv -y

python3 -m venv env
source env/bin/activate
pip install requests

source tailscale-creds.env

python3 get-tailscale-key.sh

source tailscale-key.env

sudo tailscale up --accept-routes --advertise-routes "192.168.10.0/24" --auth-key $tailnet_key

export hostname=$(hostname)

python3 authorise_routes.py