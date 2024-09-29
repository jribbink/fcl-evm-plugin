import "VirtualTransactionHelper"

access(all) contract EVMVirtualAccountManager {
    access(all) let accountRegistry: {String: VirtualAccount}

    // Stores all VirtualAccount interactions where transaction hash is the key
    access(all) let transactionRegistry: {Type: VirtualTransactionLocator}
    
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

        // TODO: Add in other transaction features that are necessary (i.e. reference block)
        // TODO: what if multiple virtual accounts are used
        // TODO: what if signer is in multiple indexes
        // TODO: run function must restrict the reference entitlements based off the transaction

        init(account: Capability<auth(Storage, Contracts, Inbox, Capabilities, Keys) &Account>) {
            self.account = account
        }

        access(all) fun verifySignature(
            signature: String,
        ): Bool {
            // TODO: NOOP for now
            return true
        }
    }

    access(all) fun runVirtualTransaction(
        transactionType: Type,
        authorizations: [{Authorization}],
        arguments: [AnyStruct],
    ): Void {
        // TODO: Verify the signature against the function hash
        // THIS IS CURRENTLY NOT DONE, but IS easily possible just not worth implementing for POC
        // We should use something like eth_signTypedData_v4
        // This should be done in the EVM
        // This should be in a well structured format
        let virtualTransaction = EVMVirtualAccountManager.transactionRegistry[transactionType]
            ?? panic("Function not found in transaction registry")


        // Resolve all authorizations
        var resolvedAuthorizations: [AnyStruct] = []
        for i, authorization in authorizations {
            if authorization.getType() == Type<EVMVirtualAccountManager.VirtualAuthorization>() {
                let virtualAuthorization = authorization as! EVMVirtualAccountManager.VirtualAuthorization
                let entitlementFilter = virtualTransaction.authorizationFactories[i]

                let virtualAccount = self.accountRegistry[String.encodeHex(virtualAuthorization.address.toVariableSized())]
                    ?? panic("Virtual account not found")
                
                if !virtualAccount.verifySignature(signature: virtualAuthorization.signature) {
                    panic("Not authorized")
                }
                
                let resolvedAuthorization = EVMVirtualAccountManager.applyEntitlementFilter(
                    account: virtualAccount.account.borrow()!,
                    expectedType: virtualTransaction.authorizationTypes[0],
                    entitlementFilter: entitlementFilter,
                )
                resolvedAuthorizations.append(resolvedAuthorization)
            } else if authorization.getType() == Type<EVMVirtualAccountManager.PreAuthorization>() {
                let preAuthorization = authorization as! EVMVirtualAccountManager.PreAuthorization
                let entitlementFilter = virtualTransaction.authorizationFactories[i]
                let resolvedAuthorization = EVMVirtualAccountManager.applyEntitlementFilter(
                    account: preAuthorization.authorization,
                    expectedType: virtualTransaction.authorizationTypes[0],
                    entitlementFilter: entitlementFilter,
                )
                resolvedAuthorizations.append(preAuthorization.authorization)
            } else {
                panic("Unknown authorization type")
            }
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
        init(
            address: Address,
            signature: String,
        ) {
            self.address = address
            self.signature = signature
        }
    }

    access(all) struct PreAuthorization: Authorization {
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
        let filtered = entitlementFilter.cast(account: account)
        if filtered.getType() != expectedType {
            panic("Entitlement filter did not return the correct type")
        }
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
    }
}