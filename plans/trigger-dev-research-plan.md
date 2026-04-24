# Trigger.dev Benchmark Plan

### 1. Library Overview

* **Description**: Trigger.dev is a background job and workflow automation platform for TypeScript/JavaScript. It focuses on "durable" execution, meaning tasks can run for a long time (no timeouts), handle retries automatically, and pause/resume based on external events (Waitpoints).
* **Ecosystem Role**: It replaces traditional serverless functions or simple message queues for complex, long-running workflows, especially those involving AI agents, human-in-the-loop approvals, and multi-step integrations.
* **Project Setup**:
    1. Initialize: `npx trigger.dev@latest init` (sets up `trigger.config.ts` and dependencies).
    2. Local Development: `npx trigger.dev@latest dev` (runs a local worker that connects to the Trigger.dev platform).
    3. Deployment: `npx trigger.dev@latest deploy`.
    4. Environment Variables: Requires `TRIGGER_SECRET_KEY` in `.env`.

### 2. Core Primitives & APIs

* **`task()`**: The primary building block. Defines an idempotent, retriable function.
    * [Documentation: Writing Tasks](https://trigger.dev/docs/writing-tasks)
* **`wait.forToken()` / `wait.createToken()`**: Pauses a run until an external callback (Human-in-the-loop) completes the token.    * [Documentation: Waitpoints](https://trigger.dev/docs/waitpoints)
* **`triggerAndWait()` / `batchTriggerAndWait()`**: Orchestrates child tasks, pausing the parent until children complete without consuming compute resources.
    * [Documentation: Orchestration](https://trigger.dev/docs/orchestration)
* **`schemaTask()`**: A task wrapper that uses Zod for payload validation.
    * [Documentation: Schema Validation](https://trigger.dev/docs/schema-validation)
* **`ai.tool()`**: Converts a task into a tool compatible with the Vercel AI SDK or other LLM frameworks.
**Code Snippets:**
```ts
// Basic Task with Retry and Schema
import { schemaTask } from "@trigger.dev/sdk";
import { z } from "zod";
export const processUserTask = schemaTask({
  id: "process-user",
  schema: z.object({ id: z.string(), email: z.string().email() }),
  retry: { maxAttempts: 3, factor: 2 },
  run: async (payload, { ctx }) => {
    // Business logic here
    return { success: true, userId: payload.id };
  },
});
// Human-in-the-loop (Waitpoints)
import { task, wait } from "@trigger.dev/sdk";
export const approvalWorkflow = task({
  id: "approval-workflow",
  run: async (payload: { amount: number }) => {
    const token = await wait.createToken({ timeout: "24h" });
    // Send token.url to Slack/Email for approval
    const result = await wait.forToken<{ approved: boolean }>(token);
    if (result.ok && result.output.approved) {
      // Proceed with payment
    }
  },
});
```

### 3. Real-World Use Cases & Templates

* **AI Agent Orchestration**: Using `triggerAndWait` to chain multiple LLM calls with different models and tools. [Example: AI Research Agent](https://github.com/triggerdotdev/examples/tree/main/ai-research-agent)
* **Real-time Data Processing**: Streaming LLM outputs or CSV processing progress back to a frontend using `streams.pipe()`. [Example: Realtime CSV Importer](https://github.com/triggerdotdev/examples/tree/main/realtime-csv-importer)
* **Human-in-the-loop Approvals**: Pausing a billing or deployment workflow until a manager clicks an "Approve" button. [Template: Human-in-the-loop](https://github.com/triggerdotdev/examples/tree/main/human-in-the-loop-workflow)

### 4. Developer Friction Points

* **`Promise.all` Restriction**: Wrapping `triggerAndWait` or `batchTriggerAndWait` in `Promise.all` is NOT supported and will cause runs to hang or fail. Developers must use the built-in `batchTriggerAndWait` method instead.
* **Import Path Confusion**: Historically, v3 used `@trigger.dev/sdk/v3`. In v4, the correct import is simply `@trigger.dev/sdk`. Using the old path or the deprecated `client.defineJob` (v2) is a common source of errors.
* **Task Exports**: Every task must be a named export from a file in the `dirs` specified in `trigger.config.ts`. Forgetting to export or placing tasks in the wrong directory results in "Task not found" errors during `dev`.

### 5. Evaluation Ideas

* **Implement a scheduled data sync**: Create a task that runs every hour to fetch data from an external API and update a database.
* **Build a multi-stage AI pipeline**: Implement a task that generates a blog post summary, then triggers a child task to translate it into three languages in parallel using `batchTriggerAndWait`.
* **Set up a human approval gate**: Create a workflow that pauses after an expensive AI generation and only proceeds to "publish" if a `wait.forToken` is completed with an `approved: true` payload.
* **Handle large-scale batch processing**: Trigger a task that processes 1,000 items by batching them into sub-tasks, ensuring correct error handling and results aggregation.
* **Integrate with Vercel AI SDK**: Convert a Trigger.dev task into a tool using `ai.tool` and use it within a `generateText` call inside another task.
* **Resilient Webhook Handler**: Build a task that receives a webhook, uses idempotency keys to prevent duplicates, and performs a multi-step integration with retries.

### 6. Sources

1. [Trigger.dev Documentation (llms-full.txt)](https://trigger.dev/docs/llms-full.txt) - Full technical reference.
2. [Trigger.dev v4 GA Announcement](https://trigger.dev/changelog/trigger-v4-ga) - Overview of new features like Waitpoints and Warm Starts.
3. [Trigger.dev Examples Repository](https://github.com/triggerdotdev/examples) - Collection of full-stack projects.
4. [Building with AI Guide](https://trigger.dev/docs/building-with-ai) - Best practices for LLM integrations and AI agents.
5. [Waitpoints Overview](https://trigger.dev/docs/waitpoints) - Detailed primitive documentation for pausing runs.

### 7. Integration
*   **Trigger.dev**: A `project_ref` and a `TRIGGER_SECRET_KEY` are required to set up the project.
