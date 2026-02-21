import { describe, it, expect } from "vitest";

describe("{{PROJECT_NAME}}", () => {
  it("should be defined", () => {
    expect(true).toBe(true);
  });

  it("should have a valid project name", () => {
    const name = "{{PROJECT_NAME}}";
    expect(name).toBeTruthy();
    expect(name).not.toContain("{{");
  });
});
