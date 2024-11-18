export function createVirtualTransactionTemplate({
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