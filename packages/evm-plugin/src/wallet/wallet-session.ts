import { Config } from "@wagmi/core";
import { Service } from "@onflow/typedefs";
import { AuthzService } from "./services/authz";
import { AccountManager } from "../account-manager";
import type { AuthnService } from "./services/authn";
import { FclService } from "./fcl-service";


export class WalletSession {
    accountManager: AccountManager
    authzService: AuthzService

    constructor(
        wagmiConfig: Config,
        private chainId: number,
        private authnService: AuthnService,
        address: string,
    ) {
        this.accountManager = new AccountManager()

        this.authzService = new AuthzService(
            wagmiConfig,
            wagmiConfig.connectors[0],
            address,
        )
    }

    getServices(): FclService[] {
        return [
            this.authnService,
            this.authzService,
        ]
    }
}