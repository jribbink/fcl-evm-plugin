import { Config, getConnectors } from "@wagmi/core";
import { flowTestnet } from "viem/chains";
import { AccountManager } from "./account-manager";
import * as fcl from "@onflow/fcl";
import { AuthnService } from "./wallet/services/authn";
import { Service } from "@onflow/typedefs";
import { WalletSession } from "./wallet/wallet-session";
import { EVM_SERVICE_METHOD } from "./constants";
import { FclService } from "./wallet/fcl-service";

export class EVMWalletPlugin {
    private accountManager: AccountManager
    private sessions: WalletSession[] = []

    constructor(private wagmiConfig: Config) {
        this.accountManager = new AccountManager()
    }

    getAuthnServices(): AuthnService[] {
        // TODO: This shouldn't re-instantiate the connectors every time
        const connectors = getConnectors(this.wagmiConfig)
        const authnServices = connectors.map(connector => new AuthnService(
            this.wagmiConfig,
            connector,
            flowTestnet.id,
            this.accountManager,
            //TODO: fix sessions not carrying
            (session) => this.onNewSession(session),
        ))
        console.log(authnServices)
        return authnServices
    }

    static createPlugin(wagmiConfig: Config) {
        const plugin = new EVMWalletPlugin(wagmiConfig)

        //TODO: revert def to return
        return {
            def: {
            name: "WagmiEVMWalletPlugin",
            f_type: "ServicePlugin",
            type: "discovery-service",
            serviceStrategy: {
                method: EVM_SERVICE_METHOD,
                exec: async (req: any) => {
                    return plugin.exec(req)
                }
            },
            services: [plugin.getAuthnServices().map(service => service.getService())[1]],
        },
        plugin,
    }
    }
    
    // TODO: Should be private
    async exec({
        service,
        body,
    }: {
        service: Service,
        body: any,
    }) {
        // Find the AuthnService that corresponds to the given service
        const authnService = this.getAuthnServices().find(authnService => doesMatchService(authnService.getService(), service))
        if (authnService) {
            return authnService.execute(body)
        }

        // Otherwise, try to find any sessions that correspond to the given service
        let sessionService: FclService | null = null
        console.log(this.sessions)
        
        for (const session of this.sessions) {
            const services = session.getServices()
            sessionService = services.find(sessionService => doesMatchService(sessionService.getService(), service)) || null
            if (sessionService) break;
        }

        if (sessionService) {
            return sessionService.execute(body)
        }

        throw new Error(`No service found for service type ${service.type}, endpoint ${service.endpoint}, and method ${service.method}`)
    }

    private async onNewSession(session: WalletSession) {
        this.sessions.push(session)
    }
}

function doesMatchService(serviceA: Service, serviceB: Service): boolean {
    return serviceA.type === serviceB.type && serviceA.endpoint === serviceB.endpoint && serviceA.method === serviceB.method
}