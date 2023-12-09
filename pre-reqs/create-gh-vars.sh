#!/bin/bash

gh variable set ARM_CLIENT_ID < vars/ARM_CLIENT_ID.txt
gh secret set ARM_CLIENT_SECRET < vars/ARM_CLIENT_SECRET.txt
gh variable set ARM_SUBSCRIPTION_ID < vars/ARM_SUBSCRIPTION_ID.txt
gh variable set ARM_TENANT_ID < vars/ARM_TENANT_ID.txt
gh variable set TAILSCALE_CLIENT_ID < vars/TAILSCALE_CLIENT_ID.txt
gh secret set TAILSCALE_CLIENT_SECRET < vars/TAILSCALE_CLIENT_SECRET.txt
gh variable set PUBLIC_SSH_KEY < ~/.ssh/authorized_keys