### 1. Library Overview
*   **Description**: Trigger.dev is an open-source background jobs framework for TypeScript/Node.js. It allows developers to write long-running, resilient workflows (tasks) using plain async code, handling retries, queuing, and state management automatically.
*   **Ecosystem Role**: It serves as a modern, developer-centric alternative to BullMQ, Inngest, or Temporal, specifically optimized for the Next.js and AI Agent ecosystem.
*   **Project Setup**:
    1.  Initialize: `npx trigger.dev@latest init` (creates `trigger.config.ts` and `/trigger` directory).
    2.  Install SDK: `npm install @trigger.dev/sdk@latest`.
    3.  Local Dev: `npx trigger.dev@latest dev` (connects local tasks to the Trigger.dev dashboard).
    4.  Environment: Requires `TRIGGER_SECRET_KEY` in `.env`.
### 2. Core Primitives & APIs
*   **`task` / `schemaTask`**: The basic unit of work. `schemaTask` adds Zod validation.
    ```typescript
    import { task, schemaTask } from "@trigger.dev/sdk";
    import { z } from "zod";
    export const myTask = schemaTask({
      id: "generate-report",
      schema: z.object({ userId: z.string() }),
      run: async (payload, { ctx }) => {
        // Implementation
        return { url: "https://..." };
      },
    });
    ```
    [Tasks Overview](https://trigger.dev/docs/tasks/overview)
*   **`wait`**: Pause execution without consuming compute resources.
    ```typescript
    import { wait } from "@trigger.dev/sdk";
    await wait.for({ seconds: 30 });
    await wait.until(new Date("2026-01-01"));
    const { data } = await wait.forToken("approval-token"); // Human-in-the-loop
    ```
    [Wait Overview](https://trigger.dev/docs/wait)
*   **`triggerAndWait` / `batch.triggerByTaskAndWait`**: Orchestrate sub-tasks.
    ```typescript
    // Sequential
    const result = await otherTask.triggerAndWait({ id: 1 });
    const data = result.unwrap(); // V4 returns a Result object
    // Parallel (Replacement for Promise.all)
    const results = await batch.triggerByTaskAndWait([
      { task: taskA, payload: { x: 1 } },
      { task: taskB, payload: { y: 2 } }
    ]);
    ```
    [Orchestration](https://trigger.dev/docs/tasks/overview#orchestrating-tasks)
*   **`ai.tool`**: Direct integration with Vercel AI SDK.
    ```typescript
    import { ai } from "@trigger.dev/sdk";
    const tool = ai.tool(mySchemaTask); // Use directly in AI SDK 'tools' object
    ```
    [AI Tool](https://trigger.dev/docs/tasks/schemaTask#ai-tool)
*   **`queue`**: Pre-defined concurrency control.
    ```typescript
    import { queue } from "@trigger.dev/sdk";
    const criticalQueue = queue({ name: "critical", concurrencyLimit: 1 });
    ```
    [Concurrency & Queues](https://trigger.dev/docs/queue-concurrency)
### 3. Real-World Use Cases & Templates
*   **AI Agent Refinement Loops**: Using `triggerAndWait` recursively to have an LLM evaluate and improve its own output. [Guide](https://trigger.dev/docs/guides/ai-agents/translate-and-refine)
*   **Human-in-the-Loop Approvals**: Using `wait.forToken` to pause a workflow until a user clicks a button in a React frontend. [Template](https://trigger.dev/docs/guides/example-projects/human-in-the-loop-workflow)
*   **Real-time Streaming Progress**: Using `streams.pipe()` to send LLM tokens or CSV processing progress back to a Next.js UI via WebSockets. [Guide](https://trigger.dev/docs/tasks/streams)
*   **Media Processing Pipelines**: Orchestrating FFmpeg or Sharp tasks with automatic retries for heavy compute. [Example](https://trigger.dev/docs/guides/examples/ffmpeg-video-processing)
### 4. Developer Friction Points
*   **Parallel Wait Error**: Developers often try `await Promise.all([task.triggerAndWait(), ...])`, which is **not supported** in Trigger.dev V4 and throws an error. They must use `batch.triggerByTaskAndWait`. [Issue #1957](https://github.com/triggerdotdev/trigger.dev/issues/1957)
*   **V4 Result Unwrapping**: In V4, `triggerAndWait` returns a `Result` object. Forgetting to call `.unwrap()` or check `.ok` before accessing output is a common bug. [Migration Guide](https://trigger.dev/docs/migrating-from-v3#triggerandwait-batchtriggerandwait)
*   **Queue Definition Requirement**: Unlike V3, V4 requires queues to be explicitly defined. On-demand queue creation in `trigger()` options no longer works. [Breaking Changes](https://trigger.dev/docs/migrating-from-v3#queue-changes)
*   **Missing `await` on Triggers**: Forgetting to `await` a `.trigger()` call can cause the parent task to finish and the process to exit before the trigger is actually sent. [Troubleshooting](https://trigger.dev/docs/troubleshooting#when-triggering-subtasks-the-parent-task-finishes-too-soon)
### 5. Evaluation Ideas
*   **Basic**: Implement a task that fetches data from an API with a custom retry strategy (exponential backoff).
*   **Intermediate**: Create a "Human-in-the-loop" email campaign where the first task generates a draft and waits for a "Send" token before proceeding.
*   **Intermediate**: Implement a parallel image processing workflow using `batch.triggerByTaskAndWait` to resize 5 images simultaneously.
*   **Advanced**: Build an AI Agent loop that uses `ai.tool` to search a database, evaluates the result, and recurses if the information is insufficient.
*   **Advanced**: Set up a complex concurrency scenario using `queue` and `concurrencyKey` to ensure only one task runs per `userId` at a time.
*   **Advanced**: Implement a real-time CSV importer that streams progress percentages to a mock frontend using `streams.pipe()`.
### 6. Integration
*   **Trigger.dev**: A `project_ref` and a `TRIGGER_SECRET_KEY` are required to set up the project.
### 7. Sources
1. [Trigger.dev llms.txt](https://trigger.dev/docs/llms.txt) - Full documentation index.
2. [Migrating from v3 to v4](https://trigger.dev/docs/migrating-from-v3.md) - List of breaking changes and new V4 features.
3. [Trigger.dev Troubleshooting](https://trigger.dev/docs/troubleshooting) - Common errors like parallel wait restrictions.
4. [Building with AI Guide](https://trigger.dev/docs/building-with-ai.md) - Patterns for LLM streaming and agent orchestration.
5. [Trigger.dev GitHub Issues](https://github.com/triggerdotdev/trigger.dev/issues) - Research on middleware and lifecycle hook bugs.