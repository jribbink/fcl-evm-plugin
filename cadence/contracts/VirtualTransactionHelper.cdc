access(all) contract interface VirtualTransactionHelper {
    access(all)
    struct interface VirtualTransaction {
        access(all) fun Prepare(
            authorizers: [AnyStruct],
        ): Void

        access(all) fun Execute(): Void

        access(all) fun Pre(): Void

        access(all) fun Post(): Void

        init(args: [AnyStruct])
    }

    access(all) fun createVirtualTransaction(
        args: [AnyStruct],
    ): {VirtualTransaction}
}