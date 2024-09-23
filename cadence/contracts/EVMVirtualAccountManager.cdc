import "VirtualTransactionHelper"

access(all) contract EVMVirtualAccountManager {
    access(all) let accountRegistry: {String: VirtualAccount}

    // Stores all VirtualAccount interactions where transaction hash is the key
    access(all) let transactionRegistry: {Type: VirtualTransactionLocator}
    access(all) struct VirtualTransactionLocator {
        access(all) let acctAddress: Address
        access(all) let name: String

        init(acctAddress: Address, name: String) {
            self.acctAddress = acctAddress
            self.name = name
        }
    }

    access(all) struct VirtualAccount {
        // TODO: is this safe
        access(self) let account: Capability<auth(Storage, Contracts, Inbox, Capabilities, Keys) &Account>

        // Would need sequence number for replay protection
        // access(all) let sequenceNumber: UInt64

        // TODO: Add in other transaction features that are necessary (i.e. reference block)
        // TODO: what if multiple virtual accounts are used
        // TODO: what if signer is in multiple indexes
        // TODO: run function must restrict the reference entitlements based off the transaction
        access(all) fun run(
            virtualTransactionType: Type,
            arguments: [AnyStruct],
            signers: [AnyStruct],
            virtualSignerIndex: UInt8,
            signature: String,
        ): Void {
            // TODO: Verify the signature against the function hash
            // THIS IS CURRENTLY NOT DONE, but IS easily possible just not worth implementing for POC
            // We should use something like eth_signTypedData_v4
            // This should be done in the EVM
            // This should be in a well structured format

            let resolvedSigners: [AnyStruct] = signers

            // TODO: this is not safe and gives more entitlements than authorized
            // There's a few workarounds I know of (i.e. simply storing types for all entitlement sets)
            // But if there's a way to dynamically downcast safely, that would be ideal
            resolvedSigners.insert(at: virtualSignerIndex, self.account.borrow()!)

            let virtualTransaction = EVMVirtualAccountManager.transactionRegistry[virtualTransactionType]
                ?? panic("Function not found in transaction registry")
            
            // Call the virtual transaction
            let txContract = getAccount(virtualTransaction.acctAddress).contracts.borrow<&{VirtualTransactionHelper}>(name: virtualTransaction.name)
                ?? panic("Could not borrow reference to VirtualTransactionHelper")

            let tx = txContract.createVirtualTransaction(args: arguments)
            
            // TODO: pre/post conditions
            tx.virtualPrepare(signers: resolvedSigners)
            tx.virtualExecute()
        }

        init(
            account: Capability<auth(Storage, Contracts, Inbox, Capabilities, Keys) &Account>
        ) {
            self.account = account
        }
    }

    access(all) fun runVirtualTransaction(
        virtualTransactionType: Type,
        arguments: [AnyStruct],
        signers: [AnyStruct],
        virtualSignerIndex: UInt8,
        evmAddress: [UInt8; 20],
        signature: String,
    ): Void {
        let virtualAccount = self.accountRegistry[String.encodeHex(evmAddress.toVariableSized())]
            ?? panic("Virtual account not found")

        virtualAccount.run(
            virtualTransactionType: virtualTransactionType,
            arguments: arguments,
            signers: signers,
            virtualSignerIndex: virtualSignerIndex,
            signature: signature,
        )
    }

    access(all)
    fun createVirtualTransaction(
        payer: auth(BorrowValue) &Account,
        transactionBody: [UInt8],
    ): Void {
        // TODO: This needs a serious security audit

        // Transaction contract deployed to ephemeral keyless account (can be solved through better methods)
        let deployer = Account(payer: payer)
        
        // TODO: temporary contract name
        let contractName = "VirtualTransactionDefinition"
        
        let deployedContract = deployer.contracts.add(name: contractName, code: transactionBody)

        // Check if deployed contract implements helper type
        if !deployedContract.isInstance(Type<{VirtualTransactionHelper}>()) {
            panic("Contract does not implement VirtualTransactionHelper.VirtualTransaction")
        }

        // Store the contract in the transaction registry
        EVMVirtualAccountManager.transactionRegistry[deployedContract.getType()] = VirtualTransactionLocator(
            acctAddress: deployer.address,
            name: contractName,
        )
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