import "EVMVirtualAccountManager"

transaction(transactionBody: [UInt8]) {
    prepare(signer: auth(BorrowValue) &Account) {
        EVMVirtualAccountManager.createVirtualTransaction(
            payer: signer,
            transactionBody: transactionBody,
        )
    }
}