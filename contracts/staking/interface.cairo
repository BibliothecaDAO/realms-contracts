## SPDX-License-Identifier: AGPL-3.0-or-later

%lang starknet

from starkware.cairo.common.uint256 import Uint256

## @title Splitter contract interface.
## @description Used to model a shared rewards accrual contract that allows other contracts to pull from it.
## @author Peteris <github.com/Pet3ris>

@contract_interface
namespace ISplitter:

    func asset() -> (asset_token_address: felt):
    end

    func claimable(account: felt) -> (claimable_holdings: Uint256):
    end

    func claim():
    end

end
