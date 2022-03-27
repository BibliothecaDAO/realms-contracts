import json
# Function to convert decimal to binary
# using built-in python function

building_costs = [6, 6, 6, 6, 6, 6, 6, 6, 6]


buildings = [
    {
        "name": "Fairgrounds",
        "id": 1,
        "costs": [2, 12, 31, 21, 7],
        "ids":[2, 2, 3, 4, 7]
    }
]


def decimalToBinary(n, bitsize):
    bit = []

    for x in n:
        num = bin(x).replace("0b", "")
        bit.append(num)

    reversed_bit = ""

    for i in reversed(bit):
        if len(i) < bitsize:
            difference = bitsize - len(i)
            reversed_bit += ("0" * difference) + i
        else:
            reversed_bit += i

    return int(reversed_bit, 2)


def createOutput(value, bitsize):
    # print(value)
    for index, x in enumerate(value):
        value[index]["costs_bitmap"] = decimalToBinary(x['costs'], bitsize)
        value[index]["ids_bitmap"] = decimalToBinary(x['ids'], bitsize)
    return value


if __name__ == '__main__':
    # f = open("scripts/cost.json", "a")
    # f.write(str(decimalToBinary(building_costs, 6)))
    with open('scripts/json_data.json', 'w') as outfile:
        outfile.write(str(createOutput(buildings, 6)))
    print(createOutput(buildings, 6))
