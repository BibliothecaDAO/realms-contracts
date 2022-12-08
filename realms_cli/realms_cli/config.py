""""
This file hold all high-level config parameters

Use:
from realms_cli.realms_cli.config import Config

... = Config.NILE_NETWORK
"""
from nile import deployments
from enum import auto


class ContractAlias(auto):
    Settling = 'Settling'
    Resources = 'Resources'
    Arbiter = 'Arbiter'
    ModuleController = 'ModuleController'
    xoroshiro128_starstar = 'xoroshiro128_starstar'
    Buildings = 'Buildings'
    Calculator = 'Calculator'
    Combat = 'Combat'
    Travel = 'Travel'
    Food = 'Food'
    Relics = 'Relics'
    GoblinTown = 'GoblinTown'
    Lords_ERC20_Mintable = 'Lords_ERC20_Mintable'
    Realms_ERC721_Mintable = 'Realms_ERC721_Mintable'
    S_Realms_ERC721_Mintable = 'S_Realms_ERC721_Mintable'
    Resources_ERC1155_Mintable_Burnable = 'Resources_ERC1155_Mintable_Burnable'
    Exchange_ERC20_1155 = 'Exchange_ERC20_1155'


def safe_load_deployment(alias: str, network: str):
    """Safely loads address from deployments file"""
    try:
        address, _ = next(deployments.load(alias, network))
        print(f"Found deployment for alias {alias}.")
        return address, _
    except StopIteration:
        print(f"Deployment for alias {alias} not found.")
        return None, None


def safe_load_declarations(alias: str, network: str):
    """Safely loads address from deployments file"""
    address, _ = next(deployments.load_class(alias, network), None)
    print(f"Found deployment for alias {alias}.")
    return address


def strhex_as_strfelt(strhex: str):
    """Converts a string in hex format to a string in felt format"""
    if strhex is not None:
        return str(int(strhex, 16))
    else:
        print("strhex address is None.")


class Config:
    def __init__(self, nile_network: str):
        self.nile_network = "127.0.0.1" if nile_network == "localhost" else nile_network

        self.MAX_FEE = 9999943901396300

        self.Arbiter_alias = "proxy_" + ContractAlias.Arbiter
        self.Module_Controller_alias = "proxy_" + ContractAlias.ModuleController
        self.Settling_alias = "proxy_" + ContractAlias.Settling
        self.Resources_alias = "proxy_" + ContractAlias.Resources
        self.Buildings_alias = "proxy_" + ContractAlias.Buildings
        self.Calculator_alias = "proxy_" + ContractAlias.Calculator
        self.Combat_alias = "proxy_" + ContractAlias.Combat
        self.Food_alias = "proxy_" + ContractAlias.Food
        self.Travel_alias = "proxy_" + ContractAlias.Travel
        self.Relics_alias = "proxy_" + ContractAlias.Relics
        self.GoblinTown_alias = "proxy_" + ContractAlias.GoblinTown

        self.Lords_ERC20_Mintable_alias = "proxy_" + ContractAlias.Lords_ERC20_Mintable
        self.Realms_ERC721_Mintable_alias = "proxy_" + \
            ContractAlias.Realms_ERC721_Mintable
        self.S_Realms_ERC721_Mintable_alias = "proxy_" + \
            ContractAlias.S_Realms_ERC721_Mintable
        self.Resources_ERC1155_Mintable_Burnable_alias = "proxy_" + \
            ContractAlias.Resources_ERC1155_Mintable_Burnable

        self.Exchange_ERC20_1155_alias = "proxy_" + ContractAlias.Exchange_ERC20_1155

        self.ADMIN_ALIAS = "STARKNET_ADMIN_PRIVATE_KEY"
        self.ADMIN_ADDRESS, _ = safe_load_deployment(
            "account-0", self.nile_network)

        self.INITIAL_LORDS_SUPPLY = 500000000 * (10 ** 18)

        self.USER_ALIAS = "STARKNET_ADMIN_PRIVATE_KEY"
        self.USER_ADDRESS, _ = safe_load_deployment(
            "account-0", self.nile_network)

        self.ARBITER_ADDRESS, _ = safe_load_deployment(
            ContractAlias.Arbiter, self.nile_network)
        self.CONTROLLER_ADDRESS, _ = safe_load_deployment(
            ContractAlias.ModuleController, self.nile_network)

        self.ARBITER_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_" + ContractAlias.Arbiter, self.nile_network)
        self.CONTROLLER_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_" + ContractAlias.ModuleController, self.nile_network)

        self.LORDS_ADDRESS, _ = safe_load_deployment(
            ContractAlias.Lords_ERC20_Mintable, self.nile_network)
        self.REALMS_ADDRESS, _ = safe_load_deployment(
            ContractAlias.Realms_ERC721_Mintable, self.nile_network)
        self.RESOURCES_ADDRESS, _ = safe_load_deployment(
            ContractAlias.Resources_ERC1155_Mintable_Burnable, self.nile_network)
        self.S_REALMS_ADDRESS, _ = safe_load_deployment(
            ContractAlias.S_Realms_ERC721_Mintable, self.nile_network)
        self.CRYPTS_ADDRESS, _ = safe_load_deployment(
            "crypts", self.nile_network)
        self.S_CRYPTS_ADDRESS, _ = safe_load_deployment(
            "s_crypts", self.nile_network)

        self.LORDS_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_" + ContractAlias.Lords_ERC20_Mintable, self.nile_network)
        self.REALMS_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_" + ContractAlias.Realms_ERC721_Mintable, self.nile_network)
        self.RESOURCES_MINT_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_" + ContractAlias.Resources_ERC1155_Mintable_Burnable, self.nile_network)
        self.S_REALMS_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_" + ContractAlias.S_Realms_ERC721_Mintable, self.nile_network)
        # self.CRYPTS_PROXY_ADDRESS, _ = safe_load_deployment("proxy_crypts", self.nile_network)
        # self.S_CRYPTS_PROXY_ADDRESS, _ = safe_load_deployment("proxy_s_crypts", self.nile_network)

        self.SETTLING_ADDRESS, _ = safe_load_deployment(
            ContractAlias.Settling, self.nile_network)
        self.RESOURCES_ADDRESS, _ = safe_load_deployment(
            ContractAlias.Resources, self.nile_network)
        self.BUILDINGS_ADDRESS, _ = safe_load_deployment(
            ContractAlias.Buildings, self.nile_network)
        self.CALCULATOR_ADDRESS, _ = safe_load_deployment(
            ContractAlias.Calculator, self.nile_network)
        self.COMBAT_ADDRESS, _ = safe_load_deployment(
            ContractAlias.Combat, self.nile_network)
        # self.L07_CRYPTS_ADDRESS, _ = safe_load_deployment("L07_Crypts", self.nile_network)

        self.SETTLING_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_" + ContractAlias.Settling, self.nile_network)
        self.RESOURCES_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_" + ContractAlias.Resources, self.nile_network)
        self.BUILDINGS_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_" + ContractAlias.Buildings, self.nile_network)
        self.CALCULATOR_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_" + ContractAlias.Calculator, self.nile_network)
        self.L06_COMBAT_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_" + ContractAlias.Combat, self.nile_network)
        # self.L07_CRYPTS_PROXY_ADDRESS, _ = safe_load_deployment("proxy_L07_Crypts", self.nile_network)

        self.XOROSHIRO_ADDRESS, _ = safe_load_deployment(
            ContractAlias.xoroshiro128_starstar, self.nile_network)

        self.Exchange_ERC20_1155_ADDRESS, _ = safe_load_deployment(
            "Exchange_ERC20_1155", self.nile_network)
        self.Exchange_ERC20_1155_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_Exchange_ERC20_1155", self.nile_network)

        self.GUILD_PROXY_CONTRACT, _ = safe_load_deployment(
            "proxy_GuildContract", self.nile_network
        )

        self.PROXY_NEXUS, _ = safe_load_deployment(
            "proxy_SingleSidedStaking", self.nile_network)

        self.PROXY_SPLITTER, _ = safe_load_deployment(
            "proxy_Splitter", self.nile_network)

        self.GOBLIN_TOWN_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_GoblinTown", self.nile_network)

        self.RESOURCES = [
            "Wood",
            "Stone",
            "Coal",
            "Copper",
            "Obsidian",
            "Silver",
            "Ironwood",
            "ColdIron",
            "Gold",
            "Hartwood",
            "Diamonds",
            "Sapphire",
            "Ruby",
            "DeepCrystal",
            "Ignium",
            "EtherealSilica",
            "TrueIce",
            "TwilightQuartz",
            "AlchemicalSilver",
            "Adamantine",
            "Mithral",
            "Dragonhide",
            # "DesertGlass",
            # "DivineCloth",
            # "CuriousSpre",
            # "UnrefinedOre",
            # "SunkenShekel",
            # "Demonhide",
            "Wheat",
            "Fish"
        ]

        self.BUILDINGS = [
            "House",
            "StoreHouse",
            "Granary",
            "Farm",
            "FishingVillage",
            "Barracks",
            "MageTower",
            "ArcherTower",
            "Castle",
        ]

        self.LOOT = [
            "Id",
            "Slot",
            "Type",
            "Material",
            "Rank",
            "Prefix_1",
            "Prefix_2",
            "Suffix",
            "Greatness",
            "CreatedBlock",
            "XP",
            "Adventurer",
            "Bag",
        ]

        self.LOOT_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_Loot", self.nile_network)

        self.ADVENTURER = [
            "Race",
            "HomeRealm",
            "Birthdate",
            "Name",
            "Health",
            "Level",
            "Order",
            "Strength",
            "Dexterity",
            "Vitality",
            "Intelligence",
            "Wisdom",
            "Charisma",
            "Luck",
            "XP",
            "WeaponId",
            "ChestId",
            "HeadId",
            "WaistId",
            "FeetId",
            "HandsId",
            "NeckId",
            "RingId",
            "Status",
            "Beast"
        ]

        self.ADVENTURER_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_Adventurer", self.nile_network)

        self.BEAST = [
            "Id",
            "AttackType",
            "ArmorType",
            "Rank",
            "Prefix_1",
            "Prefix_2",
            "Health",
            "Adventurer",
            "XP",
            "Level",
            "SlainOnDate",
        ]

        self.BEAST_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_Beast", self.nile_network)
