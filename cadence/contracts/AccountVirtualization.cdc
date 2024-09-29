import "VirtualTransactionHelper"

access(all) contract AccountVirtualization {
    // Stores all VirtualAccount interactions where transaction hash is the key
    access(all) let transactionRegistry: {Type: VirtualTransactionLocator}
    
    access(all) struct VirtualTransactionLocator {
        access(all) let acctAddress: Address
        access(all) let name: String
        access(all) let authorizationTypes: [Type]
        access(all) let authorizationFactories: [{AccountVirtualization.EntitlementFilter}]

        init(acctAddress: Address, name: String, authorizationTypes: [Type], authorizationFactories: [{AccountVirtualization.EntitlementFilter}]) {
            self.acctAddress = acctAddress
            self.name = name
            self.authorizationTypes = authorizationTypes
            self.authorizationFactories = authorizationFactories
        }
    }

    access(all) fun runVirtualTransaction(
        transactionType: Type,
        authorizations: [{Authorization}],
        arguments: [AnyStruct],
    ): Void {
        let virtualTransaction = AccountVirtualization.transactionRegistry[transactionType]
            ?? panic("Function not found in transaction registry")

        // Resolve all authorizations
        var resolvedAuthorizations: [AnyStruct] = []
        for i, authorization in authorizations {
            // Apply the entitlement filter to the authorized account
            let entitlementFilter = virtualTransaction.authorizationFactories[i]
            let resolvedAuthorization = AccountVirtualization.applyEntitlementFilter(
                account: authorization.borrow(),
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

    access(all) struct interface Authorization {
        access(all) let address: Address
        access(contract) fun borrow(): &AnyStruct
    }

    // This should safely downcast an authorized account reference to the appropriate type
    access(all) struct interface EntitlementFilter {
        access(all) fun cast(account: &AnyStruct): &AnyStruct
    }

    access(all) fun applyEntitlementFilter(
        account: &AnyStruct,
        expectedType: Type,
        entitlementFilter: {AccountVirtualization.EntitlementFilter},
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
        authorizationFactories: [{AccountVirtualization.EntitlementFilter}],
        transactionBody: [UInt8],
    ): Void {
        let deployer = Account(payer: payer)

        let hash = HashAlgorithm.SHA3_256.hash(transactionBody)
        
        // TODO: temporary contract name
        let contractName = "VirtualTransactionDefinition"
        
        let deployedContract = deployer.contracts.add(name: contractName, code: transactionBody)

        for pubType in deployedContract.publicTypes() {
            if !pubType.isSubtype(of: Type<AccountVirtualization.VirtualTransaction>()) {
                continue
            }
            AccountVirtualization.transactionRegistry[pubType] = VirtualTransactionLocator(
                acctAddress: deployer.address,
                name: contractName,
                authorizationTypes: authorizationTypes,
                authorizationFactories: authorizationFactories,
            )
            return
        }

        panic("No VirtualTransaction found in deployed contract")
    }

    init() {
        self.transactionRegistry = {}
    }
}