import "AccountVirtualization"

access(all) contract EVMAccountVirtualization {
    // TODO: does this need more restrictions?
    access(all) let accountRegistry: {String: EVMAccountVirtualization.VirtualAccount}

    access(all) let blocksUntilExpiration: UInt64

    access(all) struct VirtualAuthorization: AccountVirtualization.Authorization {
        access(all) let address: Address
        access(all) let signature: String
        access(all) let nonce: UInt64
        access(all) let referenceBlockId: [UInt8; 32]
        // We cannot lookup a reference block by hash, so Cadence needs a "hint" to find the block
        // It is not actually used for authorization, but is used to find the block
        access(all) let referenceBlockHeight: UInt64

        init(
            address: Address,
            signature: String,
            nonce: UInt64,
            referenceBlockId: [UInt8; 32],
            referenceBlock: UInt64,
        ) {
            self.address = address
            self.signature = signature
            self.nonce = nonce
            self.referenceBlockId = referenceBlockId
            self.referenceBlockHeight = referenceBlock
        }

        access(all) fun isExpired(): Bool {
            let refBlock = getBlock(at: self.referenceBlockHeight)
            if refBlock == nil {
                return true
            }

            assert(refBlock!.id == self.referenceBlockId, message: "Reference block hash does not match")
            return getCurrentBlock().height >= self.referenceBlockHeight + EVMAccountVirtualization.blocksUntilExpiration
        }

        access(contract) fun borrow(): &AnyStruct {

            let virtualAccount = EVMAccountVirtualization.accountRegistry[String.encodeHex(self.address.toBytes())]
                ?? panic("Virtual account not found")
            
            // Verify the signature
            assert(virtualAccount.verifySignature(signature: self.signature), message: "Signature verification failed")

            // Verify the nonce
            assert(virtualAccount.nonce == self.nonce, message: "Nonce verification failed")
            virtualAccount.incrementNonce()

            // Verify the reference block
            assert(!self.isExpired(), message: "Authorization is expired")

            return virtualAccount.account.borrow() ?? panic("Could not borrow reference to virtual account")
        }
    }

    access(all) struct VirtualAccount {
        access(contract) let account: Capability<auth(Storage, Contracts, Inbox, Capabilities, Keys) &Account>
        access(all) var nonce: UInt64

        init(account: Capability<auth(Storage, Contracts, Inbox, Capabilities, Keys) &Account>) {
            self.account = account
            self.nonce = 0
        }

        access(all) fun verifySignature(
            signature: String,
        ): Bool {
            // TODO: NOOP for now
            return true
        }

        access(all) fun borrow(): &Account {
            return self.account.borrow()!
        }

        access(contract) fun incrementNonce(): Void {
            self.nonce = self.nonce + 1
        }
    }

    access(all)
    fun initializeVirtualAccount(
        payer: auth(BorrowValue) &Account,
        evmAddress: [UInt8; 20],
    ): Void {
        let account = Account(payer: payer)
        let cap = account.capabilities.account.issue<auth(Storage, Contracts, Inbox, Capabilities, Keys) &Account>()

        let virtualAccount = EVMAccountVirtualization.VirtualAccount(account: cap)
    }

    init() {
        self.accountRegistry = {}
        self.blocksUntilExpiration = 590
    }
}