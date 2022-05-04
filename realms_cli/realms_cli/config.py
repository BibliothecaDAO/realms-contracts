""""
This file hold all high-level config parameters

Use:
from realms_cli.realms_cli.config import Config

... = Config.NILE_NETWORK
"""
from nile import deployments

def safe_load_deployment(alias : str, network : str):
    """Safely loads address from deployments file"""
    try:
        address, _ = next(deployments.load(alias, network))
        print(f"Found deployment for alias {alias}.")
        return address, _
    except StopIteration:
        print(f"Deployment for alias {alias} not found.")
        return None, None

def strhex_as_strfelt(strhex : str):
    """Converts a string in hex format to a string in felt format"""
    if strhex is not None:
        return str(int(strhex, 16))
    else:
        print("strhex address is None.")

class Config:
    def __init__(self, nile_network : str):
        self.nile_network = "127.0.0.1" if nile_network=="localhost" else nile_network

        

        self.ADMIN_ALIAS = "STARKNET_ADMIN_PRIVATE_KEY"
        self.ADMIN_ADDRESS, _ = safe_load_deployment("account-0", self.nile_network)

        self.INITIAL_LORDS_SUPPLY = 500000000 * (10 ** 18)

        self.USER_ALIAS = "STARKNET_PRIVATE_KEY"    
        self.USER_ADDRESS, _ = safe_load_deployment("account-1", self.nile_network)

        self.ARBITER_ADDRESS, _ = safe_load_deployment("arbiter", self.nile_network)
        self.CONTROLLER_ADDRESS, _ = safe_load_deployment("moduleController", self.nile_network)

        self.LORDS_ADDRESS, _ = safe_load_deployment("lords", self.nile_network)
        self.REALMS_ADDRESS, _ = safe_load_deployment("realms", self.nile_network)
        self.RESOURCES_ADDRESS, _ = safe_load_deployment("resources", self.nile_network)
        self.S_REALMS_ADDRESS, _ = safe_load_deployment("s_realms", self.nile_network)

        self.L01_SETTLING_ADDRESS, _ = safe_load_deployment("L01_Settling", self.nile_network)
        self.S01_SETTLING_ADDRESS, _ = safe_load_deployment("S01_Settling", self.nile_network)
        self.L02_RESOURCES_ADDRESS, _ = safe_load_deployment("L02_Resources", self.nile_network)
        self.S02_RESOURCES_ADDRESS, _ = safe_load_deployment("S02_Resources", self.nile_network)
        self.L03_BUILDINGS_ADDRESS, _ = safe_load_deployment("L03_Buildings", self.nile_network)
        self.S03_BUILDINGS_ADDRESS, _ = safe_load_deployment("S03_Buildings", self.nile_network)
        self.L04_CALCULATOR_ADDRESS, _ = safe_load_deployment("L04_Calculator", self.nile_network)
        self.L05_WONDERS_ADDRESS, _ = safe_load_deployment("L05_Wonders", self.nile_network)
        self.S05_WONDERS_ADDRESS, _ = safe_load_deployment("S05_Wonders", self.nile_network)
        self.L06_COMBAT_ADDRESS, _ = safe_load_deployment("L06_Combat", self.nile_network)
        self.S06_COMBAT_ADDRESS, _ = safe_load_deployment("S06_Combat", self.nile_network)
        self.XOROSHIRO_ADDRESS, _ = safe_load_deployment("xoroshiro128_starstar", self.nile_network)

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
        ]