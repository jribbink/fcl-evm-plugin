import { Connector, createConfig, getConnectors, injected, signTypedData } from "@wagmi/core"
import { flowMainnet } from "@wagmi/core/chains"
import { createClient, http } from "viem";

const config = createConfig({
    chains: [flowMainnet],
    connectors: [
        injected(),
    ],
    client({chain}) {
        return createClient({chain, transport: http()})
    },
});

const connectors = getConnectors(config)

