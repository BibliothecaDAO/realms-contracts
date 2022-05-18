# Constants utility contract
#   A set of constants that are used throughout the project
#   and/or not provided by cairo (e.g. TRUE / FALSE)
#
# MIT License

%lang starknet

# BIT SHIFTS
const SHIFT_8_1 = 2 ** 0
const SHIFT_8_2 = 2 ** 8
const SHIFT_8_3 = 2 ** 16
const SHIFT_8_4 = 2 ** 24
const SHIFT_8_5 = 2 ** 32
const SHIFT_8_6 = 2 ** 40
const SHIFT_8_7 = 2 ** 48
const SHIFT_8_8 = 2 ** 56
const SHIFT_8_9 = 2 ** 64
const SHIFT_8_10 = 2 ** 72
const SHIFT_8_11 = 2 ** 80
const SHIFT_8_12 = 2 ** 88
const SHIFT_8_13 = 2 ** 96
const SHIFT_8_14 = 2 ** 104
const SHIFT_8_15 = 2 ** 112
const SHIFT_8_16 = 2 ** 120
const SHIFT_8_17 = 2 ** 128
const SHIFT_8_18 = 2 ** 136
const SHIFT_8_19 = 2 ** 144
const SHIFT_8_20 = 2 ** 152

const SHIFT_6_1 = 2 ** 0
const SHIFT_6_2 = 2 ** 6
const SHIFT_6_3 = 2 ** 12
const SHIFT_6_4 = 2 ** 18
const SHIFT_6_5 = 2 ** 24
const SHIFT_6_6 = 2 ** 30
const SHIFT_6_7 = 2 ** 36
const SHIFT_6_8 = 2 ** 42
const SHIFT_6_9 = 2 ** 48
const SHIFT_6_10 = 2 ** 54
const SHIFT_6_11 = 2 ** 60
const SHIFT_6_12 = 2 ** 66
const SHIFT_6_13 = 2 ** 72
const SHIFT_6_14 = 2 ** 78
const SHIFT_6_15 = 2 ** 84
const SHIFT_6_16 = 2 ** 90
const SHIFT_6_17 = 2 ** 96
const SHIFT_6_18 = 2 ** 102
const SHIFT_6_19 = 2 ** 108
const SHIFT_6_20 = 2 ** 114

# BOOLS
const TRUE = 1
const FALSE = 0

# SETTLING
const VAULT_LENGTH = 7  # days
const DAY = 1800  # day cycle length
const VAULT_LENGTH_SECONDS = VAULT_LENGTH * DAY  # vault is always 7 * day cycle

# PRODUCTION
const BASE_RESOURCES_PER_DAY = 100
const BASE_LORDS_PER_DAY = 25

# COMBAT
const GENESIS_TIMESTAMP = 1645743897

# COMBAT
const PILLAGE_AMOUNT = 25
