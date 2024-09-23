import Test

access(all) let account = Test.createAccount()

access(all) fun testContract() {
    let err = Test.deployContract(
        name: "VirtualTransactionHelper",
        path: "../contracts/VirtualTransactionHelper.cdc",
        arguments: [],
    )

    Test.expect(err, Test.beNil())
}