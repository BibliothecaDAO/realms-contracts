import json


building_costs = [6, 6, 6, 6, 6, 6, 6, 6, 6]


buildings = [
    {
        "name": "Fairgrounds",
        "id": 1,
        "costs": [2, 12, 31, 21, 7],
        "ids":[2, 2, 3, 4, 7]
    }
]


realms = json.load(open('scripts/realms.json'))

resources = json.load(open('scripts/resources.json'))

orders = json.load(open('scripts/orders.json'))

wonders = json.load(open('scripts/wonders.json'))


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
    print(reversed_bit)
    return int(reversed_bit, 2)


def createOutput(value, bitsize):
    # print(value)
    for index, x in enumerate(value):
        value[index]["costs_bitmap"] = decimalToBinary(x['costs'], bitsize)
        value[index]["ids_bitmap"] = decimalToBinary(x['ids'], bitsize)
    return value


def mapRealm(value):
    traits = []
    resourceIds = []
    wonder = []
    order = []

    for a in value['attributes']:

        # traits
        if a['trait_type'] == "Cities":
            traits.append(a['value'])
        if a['trait_type'] == "Regions":
            traits.append(a['value'])
        if a['trait_type'] == "Rivers":
            traits.append(a['value'])
        if a['trait_type'] == "Harbors":
            traits.append(a['value'])

        # add resources
        if a['trait_type'] == "Resource":
            for b in resources:
                if b['trait'] == a['value']:
                    resourceIds.append(b['id'])

        # add wonders
        if a['trait_type'] == "Wonder (translated)":
            for index, w in enumerate(wonders):
                if w["trait"] == a['value']:
                    # adds index in arrary TODO: Hardcode Ids
                    wonder.append(index + 1)

        # add order
        if a['trait_type'] == "Order":
            for o in orders:
                if o["name"] in a['value']:
                    order.append(o["id"])

    # resource length to help with iteration in app
    resourceLength = [len(resourceIds)]

    # add extra 0 to fill up map if less than the max of 7 resources
    if len(resourceIds) < 7:
        for _ in range(7 - len(resourceIds)):
            resourceIds.append(0)

    # add extra 0 to fill wonder gap if none exist
    if len(wonder) < 1:
        wonder.append(0)

    # concat all together
    meta = traits + resourceLength + resourceIds + wonder + order
    print(meta)
    print(decimalToBinary(meta, 8))
    return decimalToBinary(meta, 8)


if __name__ == '__main__':

    f = open("scripts/realms_bit.json", "a")
    output = []
    for index in range(8000):
        output.append({str(index + 1): mapRealm(realms[str(index + 1)])})

    f.write(str(output))

    # with open('scripts/json_data.json', 'w') as outfile:
    #     outfile.write(str(createOutput(buildings, 6)))

    # print(createOutput(buildings, 6))
