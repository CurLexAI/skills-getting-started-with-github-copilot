export const SUPPORTED_AGENT_RUNTIMES = ["python", "node", "hybrid"] as const;

export type SupportedAgentRuntime = (typeof SUPPORTED_AGENT_RUNTIMES)[number];

export interface NormalizedAgentDefinition {
  id: string;
  name: string;
  execution: {
    runtime: SupportedAgentRuntime;
  };
  capabilities: string[];
  contexts: {
    allowed: string[];
  };
  role?: string;
  enable_reasoning?: boolean;
  category?: string;
}
