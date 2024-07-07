import { createPackageAnalyzer } from "@lit-labs/analyzer/package-analyzer.js";
import * as path from "path";
import * as CodeGen from "elm-codegen";

const packagePath = path.resolve("../design-system-poc/src/my-element.ts");
//@ts-ignore
const analyzer = createPackageAnalyzer(packagePath);
// const aaaa = analyzer.getModule(
//   //@ts-ignore
//   path.resolve(packagePath, "./src/my-element.ts")
// );

const moduleDeclarations = analyzer.getPackage().getLitElementModules();
const declarations = moduleDeclarations.flatMap((a) => a.declarations);

console.log(declarations.map((a) => a));

CodeGen.run("Generate.elm", {
  debug: true,
  output: "generated",
  flags: {},
  cwd: "./codegen",
});
