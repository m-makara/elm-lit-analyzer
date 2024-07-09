import { createPackageAnalyzer } from "@lit-labs/analyzer/package-analyzer.js";
import * as path from "path";
import * as CodeGen from "elm-codegen";

const packagePath = path.resolve("../design-system-poc/src/my-element.ts");
//@ts-ignore
const analyzer = createPackageAnalyzer(packagePath);

const moduleDeclarations = analyzer.getPackage().getLitElementModules();
const declarations = moduleDeclarations.flatMap((a) => a.declarations);
const reactiveProperties = declarations
  .map((a) => Array.from(a.reactiveProperties.values()))
  .flat();

const transformReactiveProperty = (
  reactiveProperty: (typeof reactiveProperties)[0]
) => {
  const { name, typeOption, attribute } = reactiveProperty;
  return { name, typeOption, attribute };
};
CodeGen.run("Generate.elm", {
  debug: true,
  output: "../design-system-poc/generated",
  flags: {
    reactiveProperties: reactiveProperties.map(transformReactiveProperty),
  },
  cwd: "./codegen",
});
