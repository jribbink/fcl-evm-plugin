import "AccountVirtualization"
import "EVMAccountVirtualization"
import "Dummy"

transaction(
    authorizations: {String: {AccountVirtualization.Authorization}},
    args: [AnyStruct],
) {
    prepare(relayer: auth(Storage) &Account) {
        let nonce = relayer.storage.borrow<auth(AccountVirtualization.Increment) &AccountVirtualization.Nonce>(from: /storage/virtualizationNonce)
            ?? panic("Nonce not found")

        // Resolve authorizations based on the provided addresses
        let resolvedAuthorizations: [{AccountVirtualization.Authorization}] = []


        AccountVirtualization.runVirtualTransaction(
            transactionType: Type<Dummy.VirtualTransaction>(),
            args: args,
            authorizations: authorizations,
            nonce: nonce,
        )
    }
}