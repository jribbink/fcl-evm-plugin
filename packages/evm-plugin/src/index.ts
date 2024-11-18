import { Connector, createConfig, getConnectors, injected, signTypedData } from "@wagmi/core"
import { flowMainnet } from "@wagmi/core/chains"
import { createClient, http } from "viem";

export const dummyConfig = createConfig({
    chains: [flowMainnet],
    connectors: [
        injected(),
    ],
    client({chain}) {
        return createClient({chain, transport: http()})
    },
});

export {EVMWalletPlugin} from "./evm-wallet-plugin"