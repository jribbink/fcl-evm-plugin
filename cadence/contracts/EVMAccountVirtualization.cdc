import "AccountVirtualization"

access(all) contract EVMAccountVirtualization {
    // TODO: does this need more restrictions?
    access(all) let accountRegistry: {String: EVMAccountVirtualization.VirtualAccount}

    access(all) let blocksUntilExpiration: UInt64

    access(all) struct Authorization: AccountVirtualization.Authorization {
        access(all) let address: Address
        access(all) let evmAddress: [UInt8; 20]
        access(all) let signature: String
        access(all) let referenceBlockId: [UInt8; 32]
        // We cannot lookup a reference block by hash, so Cadence needs a "hint" to find the block
        // It is not actually used for authorization, but is used to find the block
        access(all) let referenceBlockHeight: UInt64

        init(
            evmAddress: [UInt8; 20],
            signature: String,
            referenceBlockId: [UInt8; 32],
            referenceBlockHeight: UInt64,
        ) {
            self.address = EVMAccountVirtualization.accountRegistry[String.encodeHex(evmAddress.toVariableSized())]!.borrow().address
            self.evmAddress = evmAddress
            self.signature = signature
            self.referenceBlockId = referenceBlockId
            self.referenceBlockHeight = referenceBlockHeight
        }

        access(all) fun isExpired(): Bool {
            let refBlock = getBlock(at: self.referenceBlockHeight)
            if refBlock == nil {
                return true
            }

            assert(refBlock!.id == self.referenceBlockId, message: "Reference block hash does not match")
            return getCurrentBlock().height >= self.referenceBlockHeight + EVMAccountVirtualization.blocksUntilExpiration
        }

        access(contract) fun borrow(
            virtualTransaction: AccountVirtualization.VirtualTransaction,
        ): &AnyStruct {
            let virtualAccount = EVMAccountVirtualization.accountRegistry[String.encodeHex(self.address.toBytes())]
                ?? panic("Virtual account not found")
            
            // Verify the signature
            assert(
                virtualAccount.verifySignature(
                    virtualTransaction: virtualTransaction,
                    signature: self.signature,
                ),
                message: "Signature verification failed"
            )

            // Verify the reference block
            assert(!self.isExpired(), message: "Authorization is expired")

            return virtualAccount.account.borrow() ?? panic("Could not borrow reference to virtual account")
        }
    }

    access(all) struct VirtualAccount {
        access(contract) let account: Capability<auth(Storage, Contracts, Inbox, Capabilities, Keys) &Account>

        init(account: Capability<auth(Storage, Contracts, Inbox, Capabilities, Keys) &Account>) {
            self.account = account
        }

        access(all) fun verifySignature(
            virtualTransaction: AccountVirtualization.VirtualTransaction,
            signature: String,
        ): Bool {
            // TODO: NOOP for now
            return true
        }

        access(all) fun borrow(): &Account {
            return self.account.borrow()!
        }
    }

    access(all)
    fun createVirtualAccount(
        payer: auth(BorrowValue) &Account,
        evmAddress: [UInt8; 20],
    ): VirtualAccount {
        // TODO: Charge for storage
        let account = Account(payer: payer)
        let cap = account.capabilities.account.issue<auth(Storage, Contracts, Inbox, Capabilities, Keys) &Account>()

        let virtualAccount = EVMAccountVirtualization.VirtualAccount(account: cap)

        EVMAccountVirtualization.accountRegistry[String.encodeHex(evmAddress.toVariableSized())] = virtualAccount

        return virtualAccount
    }

    init() {
        self.accountRegistry = {}
        self.blocksUntilExpiration = 590
    }
}