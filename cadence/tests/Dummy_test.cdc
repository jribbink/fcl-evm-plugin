import Test

access(all) let account = Test.createAccount()

access(all) fun testContract() {
    let err = Test.deployContract(
        name: "Dummy",
        path: "../contracts/Dummy.cdc",
        arguments: [],
    )

    Test.expect(err, Test.beNil())
}