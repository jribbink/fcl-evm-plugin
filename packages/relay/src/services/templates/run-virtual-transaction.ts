export function generate({
    accountVirtualizationAddress,
    evmAccountVirtualizationAddress,
    virtualTxHelperAddress,
    virtualTxHelperName,
    virtualTxStructName,
    authorizations,
}: {
    accountVirtualizationAddress: string,
    evmAccountVirtualizationAddress: string,
    virtualTxHelperAddress: string,
    virtualTxHelperName: string,
    virtualTxStructName: string,
    authorizations: {
        name: string,
        isEVM: boolean,
    }[],
}): string {
    return `import AccountVirtualization from ${accountVirtualizationAddress}
import EVMAccountVirtualization from ${evmAccountVirtualizationAddress}
import ${virtualTxHelperName} from ${virtualTxHelperAddress}

transaction(
    authorizations: {String: {AccountVirtualization.Authorization}},
    args: [AnyStruct],
) {
    prepare(relayer: auth(Storage) &Account) {
        let nonce = relayer.storage.borrow<auth(AccountVirtualization.Increment) &AccountVirtualization.Nonce>(from: /storage/virtualizationNonce)
            ?? panic("Nonce not found")

        // Resolve authorizations based on the provided addresses
        let resolvedAuthorizations: [{AccountVirtualization.Authorization}] = []

        AccountVirtualization.runVirtualTransaction(
            transactionType: Type<${virtualTxHelperName}.${virtualTxStructName}>(),
            args: args,
            authorizations: {${authorizations.map(({ name, isEVM }) => `
                "${name}": ${isEVM ? `authorizations["${name}"]` : `${name}`},`).join('')}
            },
            nonce: nonce,
        )
    }
}`
}