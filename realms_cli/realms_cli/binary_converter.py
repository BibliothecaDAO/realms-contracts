import json

def decimalToBinary(n, chunksize):
    bit = []

    for x in n:
        num = bin(x).replace("0b", "")
        bit.append(num)

    reversed_bit = ""

    for i in reversed(bit):
        if len(i) < chunksize:
            difference = chunksize - len(i)
            reversed_bit += ("0" * difference) + i
        else:
            reversed_bit += i
    # print(reversed_bit)
    return int(reversed_bit, 2)


def createOutput(value, chunksize):
    # print(value)
    for index, x in enumerate(value):
        value[index]["costs_bitmap"] = decimalToBinary(x['costs'], chunksize)
        value[index]["ids_bitmap"] = decimalToBinary(x['ids'], chunksize)
    return value


# Maps the different attributes of a realm to a series of arra
def map_realm(value, resources, wonders, orders):
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
    return decimalToBinary(meta, 8)


# Maps the different attributes of a crypt to a series of arra
# def map_crypt(value, resources, legendary):
# TODO: Add legendary data for resource generation
def map_crypt(value, resources):
    resourceIds = []
    # legendary = []

    for a in value['attributes']:
        # add resources
        if a['trait_type'] == "Resource":
            for b in resources:
                if b['trait'] == a['value']:
                    resourceIds.append(b['id'])

        # check if legendary
        # if a['trait_type'] == "Legendary":
        #     for l in legendary:
        #         if l["yes"] in a['value']:
        #             legendary.append(1)

    # resource length to help with iteration in app
    resourceLength = 1

    # concat all together
    # meta = resourceLength + resourceIds + legendary
    meta = resourceLength + resourceIds
    return decimalToBinary(meta, 8)

if __name__ == '__main__':

    crypts = json.load(open("data/crypts.json"))
    output = []
    for index in range(10):
        print("ID: " + str(crypts["dungeons"][index]["tokenId"]))
        print("Environment: " + crypts["dungeons"][index]["environment"])
        print("Legendary: " + str(crypts["dungeons"][index]["legendary"]))
        print("\n")

    # f = open("data/realms_bit.json", "a")
    # output = []
    # for index in range(8000):
    #     output.append({str(index + 1): map_realm(realms[str(index + 1)])})

    # f.write(str(output))

    # # with open('scripts/json_data.json', 'w') as outfile:
    # #     outfile.write(str(createOutput(buildings, 6)))

    # building_costs = [6, 6, 6, 6, 6, 6, 6, 6, 6]

    # resource_ids = [1, 4, 6]
    # resource_values = [10, 10, 10, 10, 10]

    # buildings = [
    #     {
    #         "name": "Fairgrounds",
    #         "id": 1,
    #         "costs": [2, 12, 31, 21, 7],
    #         "ids":[2, 2, 3, 4, 7]
    #     }
    # ]


    # realms = json.load(open('data/realms.json'))

    # resources = json.load(open('data/resources.json'))

    # orders = json.load(open('data/orders.json'))

    # wonders = json.load(open('data/wonders.json'))

    # print(decimalToBinary(resource_ids, 8))
    # print(decimalToBinary(resource_values, 12))

    # print(map_realm(realms["1"], resources, wonders, orders))
