import "EVMVirtualAccountManager"

transaction(evmAddress: [UInt8]) {
    prepare(signer: auth(BorrowValue) &Account) {
        EVMVirtualAccountManager.initializeVirtualAccount(
            payer: signer,
            evmAddress: evmAddress.toConstantSized<[UInt8; 20]>()!,
        )
    }
}