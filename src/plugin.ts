import { Config } from "@wagmi/core";
import { createAuthn } from "./services/authn";
import { createAuthz } from "./services/authz";

export function createEVMPlugin(config: Config) {
    const authz = createAuthz(config)
    const authn = createAuthn(config, config.connectors[0], config.services)
}