import os
from nile.signer import Signer

# put your private key in the system environment variables
private_key = int(os.environ["ARGENT_KEY"])

signer = Signer(private_key)

if __name__ == "__main__":
    print(f"private: {private_key}")
    print(f"public: {hex(signer.public_key)}")
    print("--> put the public key as a dict key in NETWORK.accounts.json")
