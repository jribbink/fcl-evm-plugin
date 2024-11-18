import { CadenceParser } from "@onflow/cadence-parser";

export class TemplateService {
    constructor(
        private parser: CadenceParser,
    ) {
        this.templates = [];
    }

    deriveTemplate(code: string) {
        const ast = this.parser.parse(code);
        
    }
}

export default new TemplateService();