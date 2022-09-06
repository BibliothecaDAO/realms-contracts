""""
This file hold all high-level config parameters

Use:
from realms_cli.realms_cli.config import Config

... = Config.NILE_NETWORK
"""
from nile import deployments
from nile.core.declare import alias_exists
import os


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

        self.ADMIN_ALIAS = "STARKNET_ADMIN_PRIVATE_KEY"
        self.ADMIN_ADDRESS, _ = safe_load_deployment(
            "account-0", self.nile_network)

        self.INITIAL_LORDS_SUPPLY = 500000000 * (10 ** 18)

        self.USER_ALIAS = "STARKNET_PRIVATE_KEY"
        self.USER_ADDRESS, _ = safe_load_deployment(
            "account-1", self.nile_network)

        self.ARBITER_ADDRESS, _ = safe_load_deployment(
            "arbiter", self.nile_network)
        self.CONTROLLER_ADDRESS, _ = safe_load_deployment(
            "moduleController", self.nile_network)

        self.LORDS_ADDRESS, _ = safe_load_deployment(
            "lords", self.nile_network)
        self.REALMS_ADDRESS, _ = safe_load_deployment(
            "realms", self.nile_network)
        self.RESOURCES_ADDRESS, _ = safe_load_deployment(
            "resources", self.nile_network)
        self.S_REALMS_ADDRESS, _ = safe_load_deployment(
            "s_realms", self.nile_network)
        self.CRYPTS_ADDRESS, _ = safe_load_deployment(
            "crypts", self.nile_network)
        self.S_CRYPTS_ADDRESS, _ = safe_load_deployment(
            "s_crypts", self.nile_network)

        self.LORDS_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_lords", self.nile_network)
        self.REALMS_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_realms", self.nile_network)
        self.RESOURCES_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_resources", self.nile_network)
        self.S_REALMS_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_s_realms", self.nile_network)
        # self.CRYPTS_PROXY_ADDRESS, _ = safe_load_deployment("proxy_crypts", self.nile_network)
        # self.S_CRYPTS_PROXY_ADDRESS, _ = safe_load_deployment("proxy_s_crypts", self.nile_network)

        self.SETTLING_ADDRESS, _ = safe_load_deployment(
            "Settling", self.nile_network)
        self.RESOURCES_ADDRESS, _ = safe_load_deployment(
            "Resources", self.nile_network)
        self.BUILDINGS_ADDRESS, _ = safe_load_deployment(
            "Buildings", self.nile_network)
        self.CALCULATOR_ADDRESS, _ = safe_load_deployment(
            "Calculator", self.nile_network)
        self.L06_COMBAT_ADDRESS, _ = safe_load_deployment(
            "L06_Combat", self.nile_network)
        # self.L07_CRYPTS_ADDRESS, _ = safe_load_deployment("L07_Crypts", self.nile_network)

        self.SETTLING_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_Settling", self.nile_network)
        self.RESOURCES_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_Resources", self.nile_network)
        self.BUILDINGS_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_Buildings", self.nile_network)
        self.CALCULATOR_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_Calculator", self.nile_network)
        self.L06_COMBAT_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_L06_Combat", self.nile_network)
        # self.L07_CRYPTS_PROXY_ADDRESS, _ = safe_load_deployment("proxy_L07_Crypts", self.nile_network)

        self.XOROSHIRO_ADDRESS, _ = safe_load_deployment(
            "xoroshiro128_starstar", self.nile_network)

        self.Exchange_ERC20_1155_ADDRESS, _ = safe_load_deployment(
            "Exchange_ERC20_1155", self.nile_network)
        self.Exchange_ERC20_1155_PROXY_ADDRESS, _ = safe_load_deployment(
            "proxy_Exchange_ERC20_1155", self.nile_network)

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
