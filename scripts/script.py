import os
from nile.signer import Signer

private_key = int(os.environ["STARKNET_PRIVATE_KEY"])

signer = Signer(private_key)

if __name__ == "__main__":
    print(f"private: {private_key}")
    print(f"public: {signer.public_key}")
    print("--> put the public key as a dict key in NETWORK.accounts.json")
