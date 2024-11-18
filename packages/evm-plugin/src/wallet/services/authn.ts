import { Service } from "@onflow/typedefs";
import { Config, Connector } from "@wagmi/core";
import { AccountManager } from "../../account-manager";
import { EVM_SERVICE_METHOD } from "../../constants";
import { FclService } from "../fcl-service";
import { WalletSession } from "../wallet-session";

export class AuthnService implements FclService {
    private endpoint: string

    constructor(
        private wagmiConfig: Config,
        private connector: Connector,
        private chainId: number,
        private accountManager: AccountManager,
        private onNewSession?: (session: WalletSession) => void,
    ) {
        this.endpoint = `evm-authn-${this.connector.name}`
    }

    async execute(body: any) {
        const {accounts} = await this.connector.connect({
            chainId: this.chainId,
        })
        
        // Determine the user's address
        const address = await this.accountManager.getAccount(accounts[0])

        // Create a new WalletSession
        const walletSession = new WalletSession(
            this.wagmiConfig,
            this.chainId,
            this,
            address,
        )

        // Notify that a new session has been created
        this.onNewSession?.(walletSession)

        return {
            f_type: "AuthnResponse",
            f_vsn: "1.0.0",
            addr: address,
            services: walletSession.getServices().map(service => service.getService()),
        }
    }

    getService(): Service {
        return {
            f_type: "Service",
            f_vsn: "1.0.0",
            type: "authn",
            method: EVM_SERVICE_METHOD,
            endpoint: this.endpoint,
            provider: {
                uid: `evm-${this.connector.name}`,
                name: this.connector.name,
                description: this.connector.description,
                icon: this.connector.icon,
            },
            params: {}
        } as any
    }
}