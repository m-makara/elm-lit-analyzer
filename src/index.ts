import { createPackageAnalyzer } from "@lit-labs/analyzer/package-analyzer.js";
import { ModuleWithLitElementDeclarations } from "@lit-labs/analyzer/package-analyzer";
import {} from "@lit-labs/analyzer";
import * as path from "path";

const packagePath = path.resolve("../design-system-poc/src/my-element.ts");
//@ts-ignore
const analyzer = createPackageAnalyzer(packagePath);
// const aaaa = analyzer.getModule(
//   //@ts-ignore
//   path.resolve(packagePath, "./src/my-element.ts")
// );
const res = analyzer.getPackage().getLitElementModules();
console.log(res[0].declarations[0]);
