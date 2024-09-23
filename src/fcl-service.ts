import { Service } from "@onflow/typedefs";

export abstract class FclService {
    abstract execute(): Promise<any>
    abstract getService(): Service
}