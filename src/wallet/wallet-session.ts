import { Config } from "@wagmi/core";
import { Service } from "@onflow/typedefs";
import { AuthnService } from "./services/authn";
import { AuthzService } from "./services/authz";
import { AccountManager } from "../account-manager";

export class WalletSession {
    accountManager: AccountManager
    authzService: AuthzService

    constructor(
        wagmiConfig: Config,
        private chainId: number,
        private authnService: AuthnService,
    ) {
        this.accountManager = new AccountManager()

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