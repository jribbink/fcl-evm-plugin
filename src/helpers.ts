import * as fcl from "@onflow/fcl";

// TOOD: This helpers file is ephemeral and should be removed once the plugin is fully implemented
// In practice, the plugin would be more tightly integrated into FCL & fully abstracted away from the developer

export async function evmMutate(
    service: string,
    body: any,
) {
    // TODO: This should be abstracted away
    const currentUser = fcl.currentUser()
}