import "AccountVirtualization"

access(all) contract NativeAccountVirtualization {
    access(all) struct Authorization: AccountVirtualization.Authorization {
        access(all) let address: Address
        access(all) let authorization: &AnyStruct

        init(
            authorization: &AnyStruct,
        ) {
            self.authorization = authorization
            self.address = (authorization as! &Account).address
        }

        access(contract) fun borrow(virtualTransaction: AccountVirtualization.VirtualTransactionLocator): &AnyStruct {
            return self.authorization
        }
    }
}