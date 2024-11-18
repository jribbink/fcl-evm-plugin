access(all) contract AccountVirtualization {
    // Stores all VirtualAccount interactions where transaction hash is the key
    access(all) let transactionRegistry: {Type: VirtualTransactionDefinition}
    
    access(all) struct VirtualTransactionDefinition {
        access(all) let body: {VirtualTransactionBody}
        access(all) let argsType: Type
        access(all) let authorizationTypes: [Type]
        access(all) let authorizationFilters: [{AccountVirtualization.EntitlementFilter}]

        init(
            body: {VirtualTransactionBody},
            argsType: Type,
            authorizationTypes: [Type],
            authorizationFilters: [{AccountVirtualization.EntitlementFilter}],
        ) {
            self.body = body
            self.argsType = argsType
            self.authorizationTypes = authorizationTypes
            self.authorizationFilters = authorizationFilters
        }
    }

    access(all)
    struct interface VirtualTransactionBody {
        access(all) fun Prepare(
            authorizers: [AnyStruct],
            args: [AnyStruct],
        ): Void

        access(all) fun Execute(
            args: [AnyStruct],
        ): Void

        access(all) fun Pre(
            args: [AnyStruct],
        ): Void

        access(all) fun Post(
            args: [AnyStruct],
        ): Void
    }

    access(all) fun runVirtualTransaction(
        transactionType: Type,
        args: [AnyStruct],
        authorizations: [{Authorization}],
        nonce: auth(Increment) &Nonce,
    ): Void {
        let virtualExecutable = AccountVirtualization.transactionRegistry[transactionType]
            ?? panic("Function not found in transaction registry")

        let virtualTransaction = VirtualTransaction(
            executable: virtualExecutable,
            authorizations: authorizations,
            args: args,
            nonce: nonce,
        )
        
        // Verify the arguments
        assert(args.getType() == virtualExecutable.argsType, message: "Arguments do not match the expected type")

        // Resolve all authorizations
        var resolvedAuthorizations: [AnyStruct] = []
        for i, authorization in authorizations {
            // Apply the entitlement filter to the authorized account
            let entitlementFilter = virtualExecutable.authorizationFilters[i]
            let resolvedAuthorization = AccountVirtualization.applyEntitlementFilter(
                account: authorization.borrow(virtualTransaction: virtualTransaction),
                expectedType: virtualExecutable.authorizationTypes[i],
                entitlementFilter: entitlementFilter,
            )

            resolvedAuthorizations.append(resolvedAuthorization)
        }

        // Increment the nonce
        nonce.increment()

        // Execute the virtual transaction
        let body = virtualExecutable.body
        body.Prepare(authorizers: resolvedAuthorizations, args: args)
        body.Pre(args: args)
        body.Execute(args: args)
        body.Post(args: args)
    }

    access(all) struct VirtualTransaction {
        access(all) let executable: VirtualTransactionDefinition
        access(all) let authorizations: [{Authorization}]
        access(all) let args: AnyStruct
        access(all) let nonce: &Nonce

        init(
            executable: VirtualTransactionDefinition,
            authorizations: [{Authorization}],
            args: AnyStruct,
            nonce: &Nonce,
        ) {
            self.executable = executable
            self.authorizations = authorizations
            self.args = args
            self.nonce = nonce
        }
    }

    access(all) struct interface Authorization {
        access(all) let address: Address
        access(contract) fun borrow(virtualTransaction: VirtualTransaction): &AnyStruct
    }

    // This should safely downcast an authorized account reference to the appropriate type
    // It is not possible to dynamically downcast to a particular type, so we instead need a user-defined generator function
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
        body: {AccountVirtualization.VirtualTransactionBody},
        argsType: Type,
        authorizationTypes: [Type],
        authorizationFilters: [{AccountVirtualization.EntitlementFilter}],
    ): Void {
        AccountVirtualization.transactionRegistry[body.getType()] = VirtualTransactionDefinition(
            body: body,
            argsType: argsType,
            authorizationTypes: authorizationTypes,
            authorizationFilters: authorizationFilters,
        )
    }

    /*
     Nonce is a simple counter that is used to prevent replay attacks.
     It is formatted as a 128-bit number, with the lower 64 bits being the nonce value and the upper 64 bits being the resource UUID.
     */
    access(all) entitlement Increment
    access(all) resource Nonce {
        access(self) var value: UInt64

        access(Increment) fun increment() {
            // TODO: overflow?
            self.value = self.value + 1
        }

        access(all) fun get(): UInt128 {
            return UInt128(self.value) + (UInt128(self.uuid) << 64)
        }

        init() {
            self.value = 0
        }
    }

    access(all) fun createNonce(): @Nonce {
        return <-create Nonce()
    }

    init() {
        self.transactionRegistry = {}
    }
}