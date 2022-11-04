from collections import namedtuple

Realm = namedtuple(
    'Realm',
    'region cities harbours rivers resource_number resource_1 resource_2 resource_3 resource_4 resource_5 resource_6 resource_7 wonder order',
)


def build_realm_data(regions, cities, harbours, rivers, resource_number, resource_1, resource_2, resource_3, resource_4, resource_5, resource_6, resource_7, wonder, order) -> Realm:
    return Realm(*[regions, cities, harbours, rivers, resource_number, resource_1, resource_2, resource_3, resource_4, resource_5, resource_6, resource_7, wonder, order])


def pack_realm(realm: Realm) -> int:
    packed = (
        realm.region * 2**0
        + realm.cities * 2**8
        + realm.harbours * 2**16
        + realm.rivers * 2**24
        + realm.resource_number * 2**32
        + realm.resource_1 * 2**40
        + realm.resource_2 * 2**48
        + realm.resource_3 * 2**56
        + realm.resource_4 * 2**64
        + realm.resource_5 * 2**72
        + realm.resource_6 * 2**80
        + realm.resource_7 * 2**88
        + realm.wonder * 2**96
        + realm.order * 2**104
    )
    return packed
