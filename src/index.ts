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

const connect = async (connector: Connector) => {
    const {accounts, chainId} = await connector.connect()

    // We need to request to sign a user message
    const message = "Sign in to continue"

    const data = {
        message,
        chainId,
    }

    const signature = await signTypedData(config, {
        connector,
    })
}