import { Service } from "@onflow/typedefs";

export abstract class FclService {
    abstract execute(request: any): Promise<any>
    abstract getService(): Service
}