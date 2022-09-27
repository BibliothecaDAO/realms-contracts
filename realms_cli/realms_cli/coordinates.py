import json
from realms_cli.utils import str_to_felt

offset = 1800000


def coordinates_by_id(id):
    coords = json.load(open('data/coords.json'))
    return int(coords["features"][id-1]["geometry"]["coordinates"][0]) + offset, int(coords["features"][id-1]["geometry"]["coordinates"][1]) + offset


if __name__ == '__main__':
    coordinates_by_id(1)
