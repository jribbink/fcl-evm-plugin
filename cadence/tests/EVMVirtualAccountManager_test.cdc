import Test

access(all) let account = Test.createAccount()

access(all) fun testContract() {
    let err = Test.deployContract(
        name: "EVMVirtualAccountManager",
        path: "../contracts/EVMVirtualAccountManager.cdc",
        arguments: [],
    )

    Test.expect(err, Test.beNil())
}