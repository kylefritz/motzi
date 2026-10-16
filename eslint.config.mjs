import js from "@eslint/js";
import tseslint from "typescript-eslint";
import reactHooks from "eslint-plugin-react-hooks";
import prettier from "eslint-config-prettier";
import globals from "globals";

export default [
  {
    ignores: [
      "node_modules",
      "public",
      "vendor",
      "app/assets",
      "app/javascript/types/api.generated.ts",
    ],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: [
      "app/javascript/**/*.{js,ts,tsx}",
      "test/javascript/**/*.{js,ts,tsx}",
    ],
    languageOptions: {
      globals: { ...globals.browser },
    },
    plugins: { "react-hooks": reactHooks },
    rules: {
      ...reactHooks.configs.recommended.rules,
      "react-hooks/rules-of-hooks": "error",
      "react-hooks/exhaustive-deps": "error",
      // setState in effects is sometimes needed for derived state syncing
      "react-hooks/set-state-in-effect": "warn",
      // Loosen rules that conflict with our codebase style
      "@typescript-eslint/no-unused-vars": [
        "warn",
        { argsIgnorePattern: "^_" },
      ],
      "@typescript-eslint/no-explicit-any": "off",
      "no-console": "off",
    },
  },
  {
    files: ["test/javascript/**/*.{js,ts,tsx}"],
    languageOptions: {
      globals: { ...globals.node },
    },
  },
  {
    files: ["vite.config.mts"],
    languageOptions: {
      globals: { ...globals.node },
    },
  },
  // Must come last: turns off stylistic rules that would fight Prettier.
  prettier,
];
