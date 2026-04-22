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

describe("CLAUDE.md Cascade Demo", () => {
   describe("Phase 1: Foundation", () => {
      test("1. Root file only loads [ROOT]", () => {
         const output = runPrompt("Summarize @root-file.md");
         expectPresent(output, ["[ROOT]", "SOURCE:root"]);
         expectAbsent(output, [
            "[TOP]",
            "[MIDDLE]",
            "[BOTTOM]",
            "[BRANCH-A]",
            "[BRANCH-B]",
            "[OVERRIDE]",
         ]);
      });

      test("2. No file reference — only root rule applies", () => {
         const output = runPrompt("What is 2 + 2?");
         expectPresent(output, ["[ROOT]", "SOURCE:root"]);
         expectAbsent(output, [
            "[TOP]",
            "[MIDDLE]",
            "[BOTTOM]",
            "[BRANCH-A]",
            "[BRANCH-B]",
         ]);
      });
   });

   describe("Phase 2: Depth Cascade", () => {
      test("3. top/ adds [TOP] to [ROOT]", () => {
         const output = runPrompt("Summarize @top/top-file.md");
         expectPresent(output, ["[ROOT]", "[TOP]", "SOURCE:root", "SOURCE:top"]);
         expectAbsent(output, ["[MIDDLE]", "[BOTTOM]"]);
      });

      test("4. top/middle/ adds [MIDDLE]", () => {
         const output = runPrompt("Summarize @top/middle/middle-file.md");
         expectPresent(output, [
            "[ROOT]",
            "[TOP]",
            "[MIDDLE]",
            "SOURCE:root",
            "SOURCE:top",
            "SOURCE:middle",
         ]);
         expectAbsent(output, ["[BOTTOM]"]);
      });

      test("5. top/middle/bottom/ adds [BOTTOM]", () => {
         const output = runPrompt("Summarize @top/middle/bottom/bottom-file.md");
         expectPresent(output, [
            "[ROOT]",
            "[TOP]",
            "[MIDDLE]",
            "[BOTTOM]",
            "SOURCE:root",
            "SOURCE:top",
            "SOURCE:middle",
            "SOURCE:bottom",
         ]);
      });
   });

   describe("Phase 3: Sibling Isolation", () => {
      test("6. branch-a loads [BRANCH-A] but not [BRANCH-B]", () => {
         const output = runPrompt("Summarize @top/branch-a/branch-a-file.md");
         expectPresent(output, [
            "[ROOT]",
            "[TOP]",
            "[BRANCH-A]",
            "SOURCE:root",
            "SOURCE:top",
            "SOURCE:branch-a",
         ]);
         expectAbsent(output, ["[BRANCH-B]", "SOURCE:branch-b"]);
      });

      test("7. branch-b loads [BRANCH-B] but not [BRANCH-A]", () => {
         const output = runPrompt("Summarize @top/branch-b/branch-b-file.md");
         expectPresent(output, [
            "[ROOT]",
            "[TOP]",
            "[BRANCH-B]",
            "SOURCE:root",
            "SOURCE:top",
            "SOURCE:branch-b",
         ]);
         expectAbsent(output, ["[BRANCH-A]", "SOURCE:branch-a"]);
      });
   });

   describe("Phase 4: Multi-file Composition", () => {
      test("8. Both branches together load both sibling rules", () => {
         const output = runPrompt(
            "Summarize @top/branch-a/branch-a-file.md and @top/branch-b/branch-b-file.md",
         );
         expectPresent(output, [
            "[ROOT]",
            "[TOP]",
            "[BRANCH-A]",
            "[BRANCH-B]",
            "SOURCE:root",
            "SOURCE:top",
            "SOURCE:branch-a",
            "SOURCE:branch-b",
         ]);
      });
   });

   describe("Phase 5: Partial Override (Conflict Resolution)", () => {
      test("9. Override suppresses [ROOT] tag but independent SOURCE:root rule survives", () => {
         const output = runPrompt("Summarize @top/override/override-file.md");
         // Explicit conflict — [ROOT] tag suppressed
         expectAbsent(output, ["[ROOT]"]);
         // Deepest rule applies
         expectPresent(output, ["[OVERRIDE]"]);
         expectPresent(output, ["[TOP]"]);
         expectPresent(output, ["SOURCE:root"]);
         expectPresent(output, ["SOURCE:top"]);
      });
   });
});
