import { Config } from "@wagmi/core";
import { Service } from "@onflow/typedefs";
import { AuthnService } from "./services/authn";
import { AuthzService } from "./services/authz";
import { AccountManager } from "../account-manager";

export class EVMVirtualWallet {
    accountManager: AccountManager
    
    authnService: AuthnService
    authzService: AuthzService

    constructor(private wagmiConfig: Config, private chainId: number) {
        this.accountManager = new AccountManager()

        this.authnService = new AuthnService(
            wagmiConfig,
            wagmiConfig.connectors[0],
            this.chainId,
            this.accountManager,
        )

        this.authzService = new AuthzService(
            wagmiConfig,
            wagmiConfig.connectors[0],
            () => {
                console.warn("currently just a stub")
                return "0x1234567890abcdef1234567890abcdef12345678"
            },
            this.chainId,
        )
    }

    getServices(): Service[] {
        return [
            this.authnService.getService(),
            this.authzService.getService(),
        ]
    }
}