import os
from nile.signer import Signer

basicAlphabet = "abcdefghijklmnopqrstuvwxyz0123456789-''"
bigAlphabet = "这来"
small_size_plus = len(basicAlphabet) + 1
big_size_plus = len(bigAlphabet) + 1


def decode_felt_to_domain_string(felt):
    decoded = ""
    while felt != 0:
        code = felt % small_size_plus
        felt = felt // small_size_plus
        if code == len(basicAlphabet):
            next_felt = felt // big_size_plus
            if next_felt == 0:
                code2 = felt % big_size_plus
                felt = next_felt
                if code2 == 0:
                    decoded += basicAlphabet[0]
                else:
                    decoded += bigAlphabet[code2 - 1]
            else:
                code2 = felt % len(bigAlphabet)
                decoded += bigAlphabet[code2]
                felt = felt // len(bigAlphabet)
        else:
            decoded += basicAlphabet[code]
    return decoded


def encode(decoded):
    encoded = 0
    multiplier = 1
    for i in range(len(decoded)):
        char = decoded[i]
        try:
            index = basicAlphabet.index(char)
            if i == len(decoded) - 1 and decoded[i] == basicAlphabet[0]:
                encoded += multiplier * len(basicAlphabet)
                multiplier *= small_size_plus**2  # like adding 0
            else:
                encoded += multiplier * index
                multiplier *= small_size_plus
        except ValueError:
            encoded += multiplier * len(basicAlphabet)
            multiplier *= small_size_plus
            newid = int(i == len(decoded) - 1) + bigAlphabet.index(char)
            encoded += multiplier * newid
            multiplier *= len(bigAlphabet)
    return encoded


if __name__ == '__main__':
    print(encode('knightlawsa'))
