import "VirtualTransactionHelper"

access(all) contract Dummy: VirtualTransactionHelper {
    access(all) struct Actors {
        access(all) signer1: auth(Storage) &Account
    }

    access(all) struct VirtualTransaction: VirtualTransactionHelper.VirtualTransaction {
        access(all) fun Prepare(authorizers: [AnyStruct]): Void {
            
            // Noop, if this passes, the test is successful
        }

        access(all) fun Execute(): Void {
            // Noop, if this passes, the test is successful
        }

        access(all) fun Pre(): Void {
            // Noop, if this passes, the test is successful
        }

        access(all) fun Post(): Void {
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