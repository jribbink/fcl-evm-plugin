import "AccountVirtualization"

access(all) contract Dummy {
    access(all) struct VirtualTransaction: AccountVirtualization.VirtualTransactionBody {
        access(all) fun Prepare(authorizers: [AnyStruct], args: [AnyStruct]): Void {
            
            // Noop, if this passes, the test is successful
        }

        access(all) fun Execute(args: [AnyStruct]): Void {
            // Noop, if this passes, the test is successful
        }

        access(all) fun Pre(args: [AnyStruct]): Void {
            // Noop, if this passes, the test is successful
        }

        access(all) fun Post(args: [AnyStruct]): Void {
            // Noop, if this passes, the test is successful
        }
    }
}