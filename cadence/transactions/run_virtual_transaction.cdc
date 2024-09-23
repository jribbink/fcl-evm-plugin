import "EVMVirtualAccountManager"
import "Dummy" // Explicit import statement helps with readability/indexers

transaction(
    evmAddress: [UInt8],
    signature: String
) {
    // TODO: Who pays?  Currently paid for by a hosted signer, but there may be a way to recover fees
    prepare() {
        EVMVirtualAccountManager.runVirtualTransaction(
            virtualTransactionType: Type<Dummy>(),
            arguments: [],
            signers: [],
            virtualSignerIndex: 0,
            evmAddress: evmAddress.toConstantSized<[UInt8; 20]>()!,
            signature: ""
        )
    }
}