import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";

const registryPath = path.join(process.cwd(), ".agents/config/agents.yaml");
const sourcePath = path.join(process.cwd(), "src/services/unifiedAgentAdapter.ts");

test("mapping-style registry normalizes each agent into executable runtime", () => {
  const raw = fs.readFileSync(registryPath, "utf8");
  const agentKeys = [...raw.matchAll(/^\s{2}([a-z0-9-]+):\s*$/gm)].map((m) => m[1]);
  assert.ok(agentKeys.length > 0, "agents mapping must not be empty");

  const runtimeMap = { modal_vllm: "hybrid", local_policy: "node", node: "node", python: "python", hybrid: "hybrid" };

  for (const agentId of agentKeys) {
    const section = raw.split(new RegExp(`^\\s{2}${agentId}:\\s*$`, "m"))[1] ?? "";
    const runtimeMatch = section.match(/^\s{6}runtime:\s*"?([^"\n]+)"?/m);
    const hasModalBlock = /^\s{4}modal:\s*$/m.test(section);
    const runtimeValue = runtimeMatch?.[1] ?? (hasModalBlock ? "modal_vllm" : undefined);
    assert.ok(runtimeValue, `agent ${agentId} must define runtime or modal block`);
    assert.ok(runtimeMap[runtimeValue], `agent ${agentId} runtime '${runtimeValue}' must map to executable runtime`);
  }
});

test("adapter has explicit CONFIG_NOT_FOUND and REGISTRY_LOAD_FAILURE startup errors", () => {
  const source = fs.readFileSync(sourcePath, "utf8");
  assert.match(source, /code: "CONFIG_NOT_FOUND" \| "REGISTRY_LOAD_FAILURE"/);
  assert.match(source, /REGISTRY_LOAD_FAILURE: Agent .* unsupported runtime/);
});
