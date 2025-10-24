import sys
import requests
import argparse

def main():
    parser = argparse.ArgumentParser(description='Delete a package from prefix.dev')
    parser.add_argument('--token', required=True, help='API token')
    parser.add_argument('--package', required=True, help='Package file name')
    parser.add_argument('--channel', required=True, help='Package file name')
    args = parser.parse_args()

    token = args.token
    package_file_name = args.package
    channel = args.channel

    base_url = "https://prefix.dev/api/v1"
    subdir = "emscripten-wasm32"
    headers = {"Authorization": f"Bearer {token}"}
    delete_url = f"{base_url}/delete/{channel}/{subdir}/{package_file_name}"

    try:
        print("Deleting package...")
        response = requests.delete(delete_url, headers=headers)

        if response.status_code == 200:
            print("Package deleted successfully!")
            print(f"Response: {response.text}")
        elif response.status_code == 404:
            print("Package not found.")
        elif response.status_code == 401:
            print("Unauthorized. Check your token.")
        elif response.status_code == 403:
            print("Forbidden. You don't have permission to delete this package.")
        else:
            print(f"Error: {response.status_code}")
            print(f"Response: {response.text}")

    except requests.exceptions.RequestException as e:
        print(f"Request failed: {e}")

if __name__ == "__main__":
    main()
