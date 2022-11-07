%lang starknet

from starkware.cairo.common.uint256 import Uint256, uint256_add

from contracts.metadata.metadata import Uri
from contracts.loot.constants.adventurer import Adventurer, AdventurerState

@external
func test_metadata{range_check_ptr}() {
    alloc_locals;
    let id = Uint256(1,0);
    let race = 'Human';
    let home_realm = 'Test Realm';
    let name = 'Test';
    let order = 'Skill';
    let adventurer_state = AdventurerState(4, 5, 2, 1, 4, 2, 8, 13, 6, 0, 0, 0, 1, 4);
    let (data_1_len, data_1) = Uri.build(Uint256(7, 0), realm_name, realm_data_1, 1);

    %{
        array = []
        for i in range(ids.data_1_len):
            path = memory[ids.data_1+i]
            array.append(path.to_bytes(31, "big").decode())
        string_data = ''.join(array).replace('\x00', '')
        assert string_data == 'data:application/json,{"description":"realms","name":"Test","image":"https://d23fdhqc1jb9no.cloudfront.net/_Realms/7.svg","attributes":[{"trait_type":"Regions","value":"4"},{"trait_type":"Cities","value":"5"},{"trait_type":"Harbors","value":"2"},{"trait_type":"Rivers","value":"1"},{"trait_type":"Resource","value":"Stone"},{"trait_type":"Resource","value":"ColdIron"},{"trait_type":"Resource","value":"Ruby"},{"trait_type":"Resource","value":"Silver"},{"trait_type":"Wonder (translated)","value":"Cathedral Of Agony"},{"trait_type":"Order","value":"Skill"}]}'
    %}

    let (data_2_len, data_2) = Uri.build(Uint256(30, 0), realm_name, realm_data_2, 2);

    %{
        array = []
        for i in range(ids.data_2_len):
            path = memory[ids.data_2+i]
            array.append(path.to_bytes(31, "big").decode())
        string_data = ''.join(array).replace('\x00', '')
        assert string_data == 'data:application/json,{"description":"realms","name":"Test","image":"https://realms-assets.s3.eu-west-3.amazonaws.com/renders/30.webp","attributes":[{"trait_type":"Regions","value":"2"},{"trait_type":"Cities","value":"3"},{"trait_type":"Harbors","value":"6"},{"trait_type":"Rivers","value":"14"},{"trait_type":"Resource","value":"Wood"},{"trait_type":"Resource","value":"Obsidian"},{"trait_type":"Resource","value":"Stone"},{"trait_type":"Resource","value":"Gold"},{"trait_type":"Resource","value":"DeepCrystal"},{"trait_type":"Resource","value":"Hartwood"},{"trait_type":"Order","value":"Reflection"}]}'
    %}

    return ();
}