import { Config, Connector, signTypedData } from "@wagmi/core";
import { FclService } from "../fcl-service";
import { flowMainnet } from "viem/chains";

export class AuthzService implements FclService {
    constructor(
        private wagmiConfig: Config,
        private getAddress: () => string
        private chainId: number,
    ) {
        
    }

    async execute(request: any) {
        const payload = request.payload;

        signTypedData(this.wagmiConfig, {
            account: this.getAddress() as `0x${string}`,
            chainId: flowMainnet.id,
            data: payload,
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