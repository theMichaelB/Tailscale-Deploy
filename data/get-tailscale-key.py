import os
import requests

###
###
###
# variables to be set
reusable=False
ephemeral=True
preauthorized=False
tags=["tag:Gateways"]
###
###
###
def get_access_token(url, client_id, client_secret):
    response = requests.post(
        url,
        data={"grant_type": "client_credentials"},
        auth=(client_id, client_secret),
    )
    return response.json()["access_token"]


def get_tailnet_key(url, access_token, reusable, ephemeral, preauthorized, tags):

    json_structure = {
        "capabilities": {
            "devices": {
                "create": {
                    "reusable": reusable,
                    "ephemeral": ephemeral,
                    "preauthorized": preauthorized,
                    "tags": tags
                }
            }
        },
        "expirySeconds": 600,
        "description": "dev access"
    }
    Headers = {
        "Authorization": "Bearer " + access_token,
        "Content-Type": "application/json"
    }

    response = requests.post("https://api.tailscale.com/api/v2/tailnet/-/keys", json=json_structure, headers=Headers)
    return response.json()["key"]

def main():
    client_id = os.getenv("TAILSCALE_CLIENT_ID")
    client_secret = os.getenv("TAILSCALE_CLIENT_SECRET")

    if client_id and client_secret:
        access_token = get_access_token("https://api.tailscale.com/api/v2/oauth/token", client_id, client_secret)
        tailnet_key = get_tailnet_key("https://api.tailscale.com/api/v2/tailnet/-/keys", access_token, reusable, ephemeral, preauthorized, tags)

        # Write tailnet_key to file
        with open("/data/dev/tailscale-key.env", "w") as file:
            file.write("export tailnet_key=" + tailnet_key)


    else:
        print("client_id or client_secret environment variables are missing.")




if __name__ == "__main__":
    main()