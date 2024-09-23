access(all) contract Dummy {
    access(all) struct VirtualTransaction {
        access(all) fun run(arguments: [AnyStruct], signers: [AnyStruct]): Void {
            let signer = signers[0] as! auth(Storage, Contracts, Inbox, Capabilities, Keys) &Account
            
            // Noop, if this passes, the test is successful
        }
    }
}