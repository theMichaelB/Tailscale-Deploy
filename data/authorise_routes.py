import os
import requests
import json


def get_access_token(url, client_id, client_secret):
    response = requests.post(
        url,
        data={"grant_type": "client_credentials"},
        auth=(client_id, client_secret),
    )
    return response.json()["access_token"]

def get_tailnet_devices(url, access_token):
    response = requests.get(
        url,
        headers={"Authorization": "Bearer " + access_token},
    )
    formatted_json = json.dumps(response.json(), indent=4)
    return response.json()


def set_tailnet_devices(url, access_token, json_structure):
    Headers = {
        "Authorization": "Bearer " + access_token,
        "Content-Type": "application/json"
    }
    response = requests.post(url, json=json_structure, headers=Headers)
    return response.json()


def main():
    tailnet_key = os.getenv("tailnet_key")
    client_id = os.getenv("TAILSCALE_CLIENT_ID")
    client_secret = os.getenv("TAILSCALE_CLIENT_SECRET")
    hostname = os.getenv("hostname")

    if tailnet_key and client_id and client_secret and hostname:
        access_token = get_access_token("https://api.tailscale.com/api/v2/oauth/token", client_id, client_secret)
        tailnet_devices = get_tailnet_devices("https://api.tailscale.com/api/v2/tailnet/-/devices", access_token)
        selected_items = [item for item in tailnet_devices['devices'] if item['hostname'] == hostname]
        uri="https://api.tailscale.com/api/v2/device/" + selected_items[0]['id'] + "/routes"
        device_routes=get_tailnet_devices(uri, access_token)
        routes = { "routes": device_routes['advertisedRoutes'] }
        set_routes=set_tailnet_devices(uri, access_token, routes)
        print(set_routes)
    else:
        print("One or more environment variables are missing.")





if __name__ == "__main__":
    main()
