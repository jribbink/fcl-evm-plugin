import { Connector } from "@wagmi/core";

const dummyAddress = "0x1234567890123456789012345678901234567890";

export class EVMWallet {
    constructor(private connector: Connector) {

    }

    authz(request: any) {
        const payload = request.payload;

        const {accounts, chainId} = await connector.connect()

        return {
            f_type: "AuthzResponse",
            f_vsn: "1.0.0",
            accounts: accounts,
            chainId: chainId
        }
    }

    async authn(request: any) {
        const payload = request.payload;

        await this.connector.connect()

        return {
            f_type: "AuthnResponse",
            f_vsn: "1.0.0",
            address: dummyAddress,
            services: []
        }
    }

    getServices() {
        return [];
    }
}