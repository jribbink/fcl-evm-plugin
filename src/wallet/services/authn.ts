import { Service } from "@onflow/typedefs";
import { Config, Connector } from "@wagmi/core";
import { AccountManager } from "../../account-manager";
import { EVM_SERVICE_METHOD } from "../../constants";
import { FclService } from "../fcl-service";
import { WalletSession } from "../wallet-session";

export class AuthnService implements FclService {
    addressChangeSubscribers: ((address: string) => void)[] = []

    constructor(
        private wagmiConfig: Config,
        private connector: Connector,
        private chainId: number,
        private accountManager: AccountManager
    ) {

    }

    async execute() {
        const {accounts} = await this.connector.connect({
            chainId: this.chainId,
        })
        
        // Determine the user's address & notify subscribers
        const address = await this.accountManager.getAccount(accounts[0])
        this.addressChangeSubscribers.forEach(sub => sub(address))

        // Create a new WalletSession
        const walletSession = new WalletSession(
            this.wagmiConfig,
            this.chainId,
            this,
        )

        return {
            f_type: "AuthnResponse",
            f_vsn: "1.0.0",
            address: address,
            services: walletSession.getServices(),
        }
    }

    onAddressChange(callback: (address: string) => void): () => void {
        this.addressChangeSubscribers.push(callback)

        return () => {
            this.addressChangeSubscribers = this.addressChangeSubscribers.filter(sub => sub !== callback)
        }
    }

    getService(): Service {
        return {
            f_type: "Service",
            f_vsn: "1.0.0",
            type: "authn",
            method: EVM_SERVICE_METHOD,
            endpoint: "evm-authn",
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