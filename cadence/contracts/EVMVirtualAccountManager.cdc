access(all) contract EVMVirtualAccountManager {
    access(all) let accountRegistry: {String: VirtualAccount}

    access(all) let deployedTransactions: {String: Type}

    // Stores all VirtualAccount interactions where transaction hash is the key
    access(all) let transactionRegistry: {String: {EVMVirtualAccountManager.VirtualTransaction}}

    access(all) struct VirtualAccount {
        access(all) let account: Capability<auth(Storage, Contracts, Inbox, Capabilities, Keys) &Account>

        // TODO: Add in other transaction features that are necessary (i.e. reference block)
        // TODO: what if multiple virtual accounts are used
        // TODO: what if signer is in multiple indexes
        // TODO: run function must restrict the reference entitlements based off the transaction
        access(all) fun run(
            functionHash: String,
            arguments: [AnyStruct],
            signers: [AnyStruct],
            virtualSignerIndex: UInt8,
            signature: String,
        ): Void {
            // TODO: Verify the signature against the function hash
            // We should use something like eth_signTypedData_v4
            // This should be done in the EVM
            // This should be in a well structured format

            let resolvedSigners: [AnyStruct] = signers

            // TODO: this is not safe and gives more entitlements than authorized
            resolvedSigners[virtualSignerIndex] = self.account.borrow()

            let virtualTransaction = EVMVirtualAccountManager.transactionRegistry[functionHash]
                ?? panic("Function not found in transaction registry")
            
            // Call the virtual transaction
            virtualTransaction.run(arguments: arguments, signers: resolvedSigners)
        }

        init(account: Capability<auth(Storage, Contracts, Inbox, Capabilities, Keys) &Account>) {
            self.account = account
        }
    }

    access(all)
    struct interface VirtualTransaction {
        access(all) fun run(
            arguments: [AnyStruct],
            signers: [AnyStruct],
        ): Void
    }

    access(all)
    fun deployVirtualTransaction(
        payer: auth(BorrowValue) &Account,
        transactionBody: [UInt8],
        account: Capability<auth(Storage, Contracts, Inbox, Capabilities) &Account>
    ): Void {
        // TODO: This needs a serious security audit

        let deployer = Account(payer: payer)

        let hash = HashAlgorithm.SHA3_256.hash(transactionBody)
        
        let contractName = "VirtualTransaction_".concat(String.fromUTF8(hash)!)

        let deployedContract = deployer.contracts.add(name: contractName, code: transactionBody)

        let type = CompositeType(deployedContract.address.toString().concat(".").concat(contractName).concat(".VirtualTransaction"))!
        
        self.deployedTransactions[contractName] = type
    }

    access(all)
    fun registerVirtualTransaction(
        functionHash: [UInt8],
        virtualTransaction: {EVMVirtualAccountManager.VirtualTransaction}
    ): Void {
        // Verify that the transaction type is correct
        let deployedType = self.deployedTransactions[String.fromUTF8(functionHash)!]
            ?? panic("Virtual transaction not deployed")
            
        if !virtualTransaction.isInstance(deployedType) {
            panic("Virtual transaction type does not match deployed contract")
        }

        EVMVirtualAccountManager.transactionRegistry[String.fromUTF8(functionHash)!] = virtualTransaction
    }

    access(all)
    fun initializeVirtualAccount(
        payer: auth(BorrowValue) &Account,
        evmAddress: [UInt8; 20],
    ): Void {
        let account = Account(payer: payer)
        let cap = account.capabilities.account.issue<auth(Storage, Contracts, Inbox, Capabilities, Keys) &Account>()

        let virtualAccount = EVMVirtualAccountManager.VirtualAccount(account: cap)

        self.accountRegistry[String.fromUTF8(evmAddress.toVariableSized())!] = virtualAccount
    }

    init() {
        self.accountRegistry = {}
        self.transactionRegistry = {}
        self.deployedTransactions = {}
    }
}