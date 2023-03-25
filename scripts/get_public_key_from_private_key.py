import os
import sys
import json
from nile.signer import Signer

# Get the private key from the command line argument
if len(sys.argv) < 2:
    print("Error: Please provide the private key as an argument")
    sys.exit(1)

private_key = int(sys.argv[1])
address = sys.argv[2]

signer = Signer(private_key)

if __name__ == "__main__":
    public_key = hex(signer.public_key)


    # Create a dictionary with the public key and address
    account_info = {
        public_key: {
            "address": address,
            "index": 0,
            "alias": "STARKNET_PRIVATE_KEY"
        }
    }

    # Convert the dictionary to JSON and print it to the console
    print(json.dumps(account_info))