import "VirtualTransactionHelper"

access(all) contract EVMVirtualAccountManager {
    access(all) let accountRegistry: {String: VirtualAccount}

    // Stores all VirtualAccount interactions where transaction hash is the key
    access(all) let transactionRegistry: {String: VirtualTransactionLocator}
    access(all) struct VirtualTransactionLocator {
        access(all) let acctAddress: Address
        access(all) let name: String

        init(acctAddress: Address, name: String) {
            self.acctAddress = acctAddress
            self.name = name
        }
    }

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
            // THIS IS CURRENTLY NOT DONE, but IS easily possible just not worth implementing for POC
            // We should use something like eth_signTypedData_v4
            // This should be done in the EVM
            // This should be in a well structured format

            let resolvedSigners: [AnyStruct] = signers

            // TODO: this is not safe and gives more entitlements than authorized
            resolvedSigners.insert(at: virtualSignerIndex, self.account.borrow())

            let virtualTransaction = EVMVirtualAccountManager.transactionRegistry[functionHash]
                ?? panic("Function not found in transaction registry")
            
            // Call the virtual transaction
            let txContract = getAccount(virtualTransaction.acctAddress).contracts.borrow<&{VirtualTransactionHelper}>(name: virtualTransaction.name)
                ?? panic("Could not borrow reference to VirtualTransactionHelper")

            let tx = txContract.createVirtualTransaction(args: arguments)
            
            tx.virtualPrepare(signers: resolvedSigners)
            tx.virtualExecute()
        }

        init(account: Capability<auth(Storage, Contracts, Inbox, Capabilities, Keys) &Account>) {
            self.account = account
        }
    }

    access(all) fun runVirtualTransaction(
        functionHash: String,
        arguments: [AnyStruct],
        signers: [AnyStruct],
        virtualSignerIndex: UInt8,
        evmAddress: [UInt8; 20],
        signature: String,
    ): Void {
        let virtualAccount = self.accountRegistry[String.fromUTF8(evmAddress.toVariableSized())!]
            ?? panic("Virtual account not found")

        virtualAccount.run(
            functionHash: functionHash,
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

        let deployer = Account(payer: payer)

        let hash = HashAlgorithm.SHA3_256.hash(transactionBody)
        
        let contractName = "VirtualTransaction_".concat(String.fromUTF8(hash)!)
        
        deployer.contracts.add(name: contractName, code: transactionBody)

        let deployedRef = deployer.contracts.borrow<&{VirtualTransactionHelper}>(name: contractName)
            ?? panic("Could not borrow reference to VirtualTransactionHelper")
        
        EVMVirtualAccountManager.transactionRegistry[String.fromUTF8(hash)!] = VirtualTransactionLocator(
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

        self.accountRegistry[String.fromUTF8(evmAddress.toVariableSized())!] = virtualAccount
    }

    init() {
        self.accountRegistry = {}
        self.transactionRegistry = {}
    }
}