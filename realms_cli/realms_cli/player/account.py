# First, import click dependency
import json
import click

from ecdsa import SigningKey, SECP128r1

@click.command()
def create_pk():
    """
    Create private key
    """
    sk = SigningKey.generate(curve=SECP128r1)
    sk_string = sk.to_string()
    sk_hex = sk_string.hex()
    print(int('0x' + sk_hex, 16))
