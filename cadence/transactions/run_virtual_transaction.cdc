import "EVMVirtualAccountManager"

transaction(
    hash: String,
    evmAddress: [UInt8],
) {
    // TODO: Who pays?
    prepare() {
        EVMVirtualAccountManager.runVirtualTransaction(
            functionHash: hash,
            arguments: [],
            signers: [],
            virtualSignerIndex: 0,
            evmAddress: evmAddress.toConstantSized<[UInt8; 20]>()!,
            signature: ""
        )
    }
}