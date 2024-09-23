import { Config, Connector, signMessage } from "@wagmi/core";
import { FclService } from "../fcl-service";

export class AuthzService implements FclService {
    constructor(
        private wagmiConfig: Config,
        private connector: Connector,
    ) {}

    async execute(request: any) {
        const payload = request.payload;

        // TODO: use the sig
        const signature = await signMessage(this.wagmiConfig, {
            connector: this.connector,
            message: payload.message,
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
        return {
            f_type: "Service",
            f_vsn: "1.0.0",
            type: "authz",
            method: "authz",
            endpoint: "evm-authz",
            params: {}
        } as any
    }
}