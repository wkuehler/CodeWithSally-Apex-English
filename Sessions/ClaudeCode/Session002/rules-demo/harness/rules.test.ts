import { execSync } from "child_process";
import * as path from "path";

const PROJECT_DIR = path.resolve(__dirname, "..");
const MODEL = "claude-sonnet-4-6";

function runPrompt(prompt: string): string {
   const result = execSync(`claude -p "${prompt}" --model ${MODEL}`, {
      cwd: PROJECT_DIR,
      encoding: "utf-8",
      timeout: 120000,
   });
   return result;
}

function expectPresent(output: string, items: string[]): void {
   for (const item of items) {
      expect(output).toContain(item);
   }
}

function expectAbsent(output: string, items: string[]): void {
   for (const item of items) {
      expect(output).not.toContain(item);
   }
}

describe(".claude/rules/ Demo", () => {
   describe("Phase 1: Always-on rule", () => {
      test("1. Plain markdown loads [ALL] only", () => {
         const output = runPrompt("Summarize @plain.md");
         expectPresent(output, ["[ALL]", "SOURCE:all"]);
         expectAbsent(output, ["[JS]", "[TS]", "[TESTS]", "[SRC]", "[OVERRIDE]"]);
      });

      test("2. No file reference loads [ALL] only", () => {
         const output = runPrompt("What is 2 + 2?");
         expectPresent(output, ["[ALL]", "SOURCE:all"]);
         expectAbsent(output, ["[JS]", "[TS]", "[TESTS]", "[SRC]", "[OVERRIDE]"]);
      });
   });

   describe("Phase 2: Path-scoped rules & sibling isolation", () => {
      test("3. .js file loads [JS]", () => {
         const output = runPrompt("Summarize @example.js");
         expectPresent(output, ["[ALL]", "[JS]", "SOURCE:all"]);
         expectAbsent(output, ["[TS]", "[TESTS]", "[SRC]", "[OVERRIDE]"]);
      });

      test("4. .ts file loads [TS], not [JS]", () => {
         const output = runPrompt("Summarize @example.ts");
         expectPresent(output, ["[ALL]", "[TS]", "SOURCE:all"]);
         expectAbsent(output, ["[JS]", "[TESTS]", "[SRC]", "[OVERRIDE]"]);
      });
   });

   describe("Phase 3: Composition & cross-cutting globs", () => {
      test("5. .test.js loads [JS] + [TESTS] (cross-cutting multi-glob)", () => {
         const output = runPrompt("Summarize @example.test.js");
         expectPresent(output, ["[ALL]", "[JS]", "[TESTS]", "SOURCE:all"]);
         expectAbsent(output, ["[TS]", "[SRC]", "[OVERRIDE]"]);
      });

      test("6. Two file types compose", () => {
         const output = runPrompt("Summarize @example.js and @example.ts");
         expectPresent(output, ["[ALL]", "[JS]", "[TS]", "SOURCE:all"]);
         expectAbsent(output, ["[TESTS]", "[SRC]", "[OVERRIDE]"]);
      });

      test("7. src/*.js matches both js.md and src.md globs", () => {
         const output = runPrompt("Summarize @src/src-file.js");
         expectPresent(output, ["[ALL]", "[JS]", "[SRC]", "SOURCE:all"]);
         expectAbsent(output, ["[TS]", "[TESTS]", "[OVERRIDE]"]);
      });
   });

   describe("Phase 4: Partial override (conflict resolution)", () => {
      test("8. Override suppresses [ALL] but independent SOURCE:all survives", () => {
         const output = runPrompt("Summarize @override/override-file.js");
         expectAbsent(output, ["[ALL]"]);
         expectPresent(output, ["[OVERRIDE]"]);
         expectPresent(output, ["[JS]"]);
         expectPresent(output, ["SOURCE:all"]);
      });
   });
});
