import json

from realms_cli.binary_converter import decimal_to_binary, map_realm, map_crypt

# f = open("data/realms_bit.json", "a")
# output = []
# for index in range(8000):
#     output.append({str(index + 1): map_realm(realms[str(index + 1)])})

# f.write(str(output))

# # with open('scripts/json_data.json', 'w') as outfile:
# #     outfile.write(str(create_output(buildings, 6)))

building_costs = [6, 6, 6, 6, 6, 6, 6, 6, 6]

resource_ids = [1, 4, 6]
resource_values = [10, 10, 10, 10, 10]

buildings = [
    {
        "name": "Fairgrounds",
        "id": 1,
        "costs": [2, 12, 31, 21, 7],
        "ids":[2, 2, 3, 4, 7]
    }
]

# Quickly test Realms metadata
realms = json.load(open('data/realms.json'))
resources = json.load(open('data/resources.json'))
orders = json.load(open('data/orders.json'))
wonders = json.load(open('data/wonders.json'))

print(decimal_to_binary(resource_ids, 8))
print(decimal_to_binary(resource_values, 12))

print(map_realm(realms["1"], resources, wonders, orders))

# Quickly test Crypts metadata
crypts = json.load(open("data/crypts.json"))
environments = json.load(open("data/crypts_environments.json"))
affinities = json.load(open("data/crypts_affinities.json"))

print(map_crypt(crypts["1"], environments, affinities))
