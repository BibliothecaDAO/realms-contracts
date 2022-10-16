import json

from realms_cli.utils import str_to_felt

wonders = json.load(open('data/wonders.json'))

for item in wonders:
    print(str_to_felt(item['trait']))