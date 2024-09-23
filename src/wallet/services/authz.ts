import { Config, Connector, signMessage } from "@wagmi/core";
import { FclService } from "../fcl-service";
import { EVM_SERVICE_METHOD } from "../../constants";

export class AuthzService implements FclService {
    constructor(
        private wagmiConfig: Config,
        private connector: Connector,
        private address: string,
    ) {}

    // TODO: types here/impl
    async execute(message: any) {
        // TODO: use the sig
        const signature = await signMessage(this.wagmiConfig, {
            connector: this.connector,
            message: message,
        })
        
        return {
            f_type: "AuthzResponse",
            f_vsn: "1.0.0",
            data: {
                address: "0x1234567890abcdef1234567890abcdef12345678",
                keyId: 0,
                signingFunction: "0x1234567890abcdef1234567890abcdef12345678",
                accounts: [
                    {
                        address: "0x1234567890abcdef1234567890abcdef12345678",
                        keyId: 0,
                        signingFunction: "0x1234567890abcdef1234567890abcdef12345678",
                        hashAlgo: "SHA3_256",
                        weight: 1
                    }
                ]
            }
        }
    }

    getService() {
        const service = {
            f_type: "Service",
            f_vsn: "1.0.0",
            type: "authz",
            method: EVM_SERVICE_METHOD,
            endpoint: "evm-authz",
            params: {}
        } as any

        service.identity = {
            address: this.address,
        }

        return service
    }
}