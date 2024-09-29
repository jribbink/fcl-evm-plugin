import "VirtualTransactionHelper"

access(all) contract EVMVirtualAccountManager {
    access(all) let accountRegistry: {String: VirtualAccount}

    // Stores all VirtualAccount interactions where transaction hash is the key
    access(all) let transactionRegistry: {Type: VirtualTransactionLocator}

    access(all) let blocksUntilExpiration: UInt64
    
    access(all) struct VirtualTransactionLocator {
        access(all) let acctAddress: Address
        access(all) let name: String
        access(all) let authorizationTypes: [Type]
        access(all) let authorizationFactories: [{EVMVirtualAccountManager.EntitlementFilter}]

        init(acctAddress: Address, name: String, authorizationTypes: [Type], authorizationFactories: [{EVMVirtualAccountManager.EntitlementFilter}]) {
            self.acctAddress = acctAddress
            self.name = name
            self.authorizationTypes = authorizationTypes
            self.authorizationFactories = authorizationFactories
        }
    }

    access(all) struct VirtualAccount {
        access(contract) let account: Capability<auth(Storage, Contracts, Inbox, Capabilities, Keys) &Account>
        access(all) var nonce: UInt64

        // TODO: Add in other transaction features that are necessary (i.e. reference block)
        // TODO: what if multiple virtual accounts are used
        // TODO: what if signer is in multiple indexes
        // TODO: run function must restrict the reference entitlements based off the transaction

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

        access(contract) fun incrementNonce() {
            self.nonce = self.nonce + 1
        }
    }

    access(all) fun runVirtualTransaction(
        transactionType: Type,
        authorizations: [{Authorization}],
        arguments: [AnyStruct],
    ): Void {
        let virtualTransaction = EVMVirtualAccountManager.transactionRegistry[transactionType]
            ?? panic("Function not found in transaction registry")

        // Resolve all authorizations
        var resolvedAuthorizations: [AnyStruct] = []
        for i, authorization in authorizations {
            var rawAuthorization: &AnyStruct? = nil
            if authorization.getType() == Type<EVMVirtualAccountManager.VirtualAuthorization>() {
                let virtualAuthorization = authorization as! EVMVirtualAccountManager.VirtualAuthorization

                let virtualAccount = self.accountRegistry[String.encodeHex(virtualAuthorization.address.toVariableSized())]
                    ?? panic("Virtual account not found")
                
                // Verify the signature
                assert(virtualAccount.verifySignature(signature: virtualAuthorization.signature), message: "Signature verification failed")

                // Verify the nonce
                assert(virtualAccount.nonce == virtualAuthorization.nonce, message: "Nonce verification failed")
                virtualAccount.incrementNonce()

                // Verify the reference block
                assert(!virtualAuthorization.isExpired(), message: "Authorization is expired")

                rawAuthorization = virtualAccount.account.borrow() ?? panic("Could not borrow reference to virtual account")
            } else if authorization.getType() == Type<EVMVirtualAccountManager.NativeAuthorization>() {
                rawAuthorization = (authorization as! EVMVirtualAccountManager.NativeAuthorization).authorization
            } else {
                panic("Unknown authorization type")
            }

            // Apply the entitlement filter to the authorized account
            let entitlementFilter = virtualTransaction.authorizationFactories[i]
            let resolvedAuthorization = EVMVirtualAccountManager.applyEntitlementFilter(
                account: rawAuthorization!,
                expectedType: virtualTransaction.authorizationTypes[i],
                entitlementFilter: entitlementFilter,
            )

            resolvedAuthorizations.append(resolvedAuthorization)
        }
        
        // Call the virtual transaction
        let txContract = getAccount(virtualTransaction.acctAddress).contracts.borrow<&{VirtualTransactionHelper}>(name: virtualTransaction.name)
            ?? panic("Could not borrow reference to VirtualTransactionHelper")

        let tx = txContract.createVirtualTransaction(args: arguments)

        // Execute the virtual transaction
        tx.Prepare(authorizers: resolvedAuthorizations)
        tx.Pre()
        tx.Execute()
        tx.Post()
    }

    access(all) struct VirtualTransaction {
        access(all) let executable: {VirtualTransactionHelper.VirtualTransaction}
        access(all) let authorizations: [{Authorization}]
        access(all) let arguments: [AnyStruct]

        init(
            executable: {VirtualTransactionHelper.VirtualTransaction},
            authorizations: [{Authorization}],
            arguments: [AnyStruct],
        ) {
            self.executable = executable
            self.authorizations = authorizations
            self.arguments = arguments
        }
    }

    access(all) struct interface Authorization {}
    
    access(all) struct VirtualAuthorization: Authorization {
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
            return getCurrentBlock().height >= self.referenceBlockHeight + EVMVirtualAccountManager.blocksUntilExpiration
        }
    }

    access(all) struct NativeAuthorization: Authorization {
        access(all) let authorization: &AnyStruct

        init(
            authorization: &AnyStruct,
        ) {
            self.authorization = authorization
        }
    }

    // This should safely downcast an authorized account reference to the appropriate type
    access(all) struct interface EntitlementFilter {
        access(all) fun cast(account: &AnyStruct): &AnyStruct
    }

    access(all) fun applyEntitlementFilter(
        account: &AnyStruct,
        expectedType: Type,
        entitlementFilter: {EVMVirtualAccountManager.EntitlementFilter},
    ): &AnyStruct {
        let expectedAddress = (account as! &Account).address
        let filtered = entitlementFilter.cast(account: account)
        assert(filtered.getType() == expectedType, message: "Entitlement filter did not return the expected type")
        assert((filtered as! &Account).address == expectedAddress, message: "Entitlement filter did not return the expected address")
        return filtered
    }

    access(all)
    fun createVirtualTransaction(
        payer: auth(BorrowValue) &Account,
        authorizationTypes: [Type],
        authorizationFactories: [{EVMVirtualAccountManager.EntitlementFilter}],
        transactionBody: [UInt8],
    ): Void {
        let deployer = Account(payer: payer)

        let hash = HashAlgorithm.SHA3_256.hash(transactionBody)
        
        // TODO: temporary contract name
        let contractName = "VirtualTransactionDefinition"
        
        let deployedContract = deployer.contracts.add(name: contractName, code: transactionBody)

        for pubType in deployedContract.publicTypes() {
            if !pubType.isSubtype(of: Type<EVMVirtualAccountManager.VirtualTransaction>()) {
                continue
            }
            EVMVirtualAccountManager.transactionRegistry[pubType] = VirtualTransactionLocator(
                acctAddress: deployer.address,
                name: contractName,
                authorizationTypes: authorizationTypes,
                authorizationFactories: authorizationFactories,
            )
            return
        }

        panic("No VirtualTransaction found in deployed contract")
    }

    access(all)
    fun initializeVirtualAccount(
        payer: auth(BorrowValue) &Account,
        evmAddress: [UInt8; 20],
    ): Void {
        let account = Account(payer: payer)
        let cap = account.capabilities.account.issue<auth(Storage, Contracts, Inbox, Capabilities, Keys) &Account>()

        let virtualAccount = EVMVirtualAccountManager.VirtualAccount(account: cap)

        self.accountRegistry[String.encodeHex(evmAddress.toVariableSized())] = virtualAccount
    }

    init() {
        self.accountRegistry = {}
        self.transactionRegistry = {}
        self.blocksUntilExpiration = 590
    }
}