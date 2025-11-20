import nextCoreWebVitals from "eslint-config-next/core-web-vitals";
import simpleImportSort from "eslint-plugin-simple-import-sort";
import unusedImports from "eslint-plugin-unused-imports";

const config = [
  ...nextCoreWebVitals,
  {
    plugins: {
      "simple-import-sort": simpleImportSort,
      "unused-imports": unusedImports,
    },
    rules: {
      semi: ["error", "always"],
      "simple-import-sort/imports": "error",
      "unused-imports/no-unused-imports": "error",
    },
  },
];

export default config;
