// TODO: flesh out interface for pre and post conditions
access(all) contract interface VirtualTransactionHelper {
    access(all)
    struct interface VirtualTransaction {
        access(all) fun virtualPrepare(
            signers: [AnyStruct],
        ): Void

        access(all) fun virtualExecute(): Void

        init(args: [AnyStruct])
    }

    access(all) fun createVirtualTransaction(
        args: [AnyStruct],
    ): {VirtualTransaction}
}