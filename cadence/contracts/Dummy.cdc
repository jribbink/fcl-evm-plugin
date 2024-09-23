import "VirtualTransactionHelper"

access(all) contract Dummy: VirtualTransactionHelper {
    access(all) struct VirtualTransaction: VirtualTransactionHelper.VirtualTransaction {
        access(all) fun virtualPrepare(signers: [AnyStruct]): Void {
            let signer = signers[0] as! auth(Storage, Contracts, Inbox, Capabilities, Keys) &Account
            
            // Noop, if this passes, the test is successful
        }

        access(all) fun virtualExecute(): Void {
            // Noop, if this passes, the test is successful
        }

        init(args: [AnyStruct]) {
            // Noop, if this passes, the test is successful
        }
    }

    access(all) fun createVirtualTransaction(args: [AnyStruct]): {VirtualTransactionHelper.VirtualTransaction} {
        return VirtualTransaction(args: args)
    }
}