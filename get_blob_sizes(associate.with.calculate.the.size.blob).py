#!/usr/bin/env python3
import sys, json, subprocess

def main():
    # Read input from Terraform.
    query = json.load(sys.stdin)
    storage_account = query.get("storage_account")
    container = query.get("container")

    # Use Azure CLI to list blobs in the container.
    # (Ensure that you are logged in with 'az login' before running Terraform.)
    cmd = [
        "az", "storage", "blob", "list",
        "--account-name", storage_account,
        "--container-name", container,
        "--query", "[].{Name:name, Length:properties.contentLength}",
        "--output", "json"
    ]
    try:
        result = subprocess.check_output(cmd)
        blobs = json.loads(result)
    except subprocess.CalledProcessError as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)

    # Sum up the lengths of all blobs.
    total_length = sum(blob.get("Length") or 0 for blob in blobs)

    output = {
        "blobs": blobs,
        "total_length": total_length
    }
    json.dump(output, sys.stdout)

if __name__ == "__main__":
    main()
