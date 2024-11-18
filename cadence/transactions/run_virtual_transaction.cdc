import "AccountVirtualization"
import "EVMAccountVirtualization"
import "Dummy"

transaction(
    authorizations: [EVMAccountVirtualization.Authorization],
    args: [AnyStruct],
) {
    prepare(relayer: auth(Storage) &Account) {
        let nonce = relayer.storage.borrow<&AccountVirtualization.Nonce>(from: /storage/virtualizationNonce)
            ?? panic("Nonce not found")

        AccountVirtualization.runVirtualTransaction(
            transactionType: Type<Dummy.VirtualTransaction>(),
            args: args,
            authorizations: authorizations,
            nonce: nonce,
        )
    }
}