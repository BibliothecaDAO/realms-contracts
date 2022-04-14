## What to do?
1. Deploy Loot Realms ERC721
2. Deploy L2 Loot Realms ERC721
3. Deploy Bridge with __l2_realms_addr__
4. Deploy L1 RealmsBridgeLockbox
5. L1 RealmsBridgeLockbox: do setL2BridgeAddress()

### L1 - ensure that:
- Realms address is set in **Lockbox**
- StarknetCore address is set in **Lockbox**

### L2 - ensure that:
- Realms address is set in **Bridge**
- Bridge address is set in **Realms**

### Setting both L1 and L2 - ensure that:
- L1 Lockbox address is set in **L2 Bridge**
- L2 Bridge address is set in **L1 Lockbox**