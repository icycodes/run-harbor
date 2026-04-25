# Trigger.dev Benchmark Plan

### 1. Library Overview

* **Description**: Trigger.dev is an open-source background jobs framework and platform that allows developers to write reliable, long-running workflows in plain async TypeScript/JavaScript. It automatically handles retries, queuing, and elastic scaling without function timeouts.
* **Ecosystem Role**: It replaces traditional message brokers (like RabbitMQ or Redis) and serverless function orchestrators by providing a fully managed (or self-hostable) execution engine for background tasks, AI agents, and ETL pipelines.
* **Project Setup**:
  1. Create an account at `cloud.trigger.dev` to obtain API keys.
  2. In your project root, run the initialization CLI:
     ```bash
     npx trigger.dev@latest init
     ```
  3. Set the `TRIGGER_SECRET_KEY` in your `.env` file.
  4. Start the local development server to sync your `/trigger` directory with the cloud dashboard:
     ```bash
     npx trigger.dev@latest dev
     ```

### 2. Core Primitives & APIs

* **`task`**: The fundamental unit of work. It requires an `id` and an async `run` function.
  ```typescript
  import { task } from "@trigger.dev/sdk";

  export const helloWorld = task({
    id: "hello-world",
    run: async (payload: { message: string }, { ctx }) => {
      console.log(payload.message);
      return { success: true };
    },
  });
  ```
  [Documentation: Tasks Overview](https://trigger.dev/docs/tasks/overview)

* **`wait`**: Primitives to pause execution without consuming compute resources. Includes `wait.for()`, `wait.until()`, and `wait.forToken()` (human-in-the-loop).
  ```typescript
  import { task, wait } from "@trigger.dev/sdk";

  export const waitTask = task({
    id: "wait-task",
    run: async (payload: any) => {
      await wait.for({ seconds: 10 }); // Task is frozen and doesn't bill compute
    },
  });
  ```
  [Documentation: Wait Overview](https://trigger.dev/docs/wait)

* **Lifecycle Hooks**: Hooks like `onStartAttempt`, `onSuccess`, `onFailure`, and `onCancel` to manage the task lifecycle.
  ```typescript
  export const taskWithHooks = task({
    id: "task-with-hooks",
    onSuccess: async ({ payload, output, ctx }) => {
      console.log("Task succeeded!");
    },
    run: async (payload: any) => { /* ... */ },
  });
  ```
  [Documentation: Lifecycle Functions](https://trigger.dev/docs/tasks/overview#lifecycle-functions)

* **Triggering Tasks**: Triggering a task from your backend code using the generated handle.
  ```typescript
  import { tasks } from "@trigger.dev/sdk";
  import type { helloWorld } from "./trigger/hello-world"; // Type-only import

  const handle = await tasks.trigger<typeof helloWorld>("hello-world", { message: "Hello!" });
  ```
  [Documentation: Triggering](https://trigger.dev/docs/triggering)

### 3. Real-World Use Cases & Templates

* **AI Agents with Human-in-the-Loop**: A meme generator or content approval workflow that uses `wait.forToken()` to pause an AI agent until a user reviews and approves the generated content.
  [Meme Generator Template](https://trigger.dev/docs/guides/example-projects/meme-generator-human-in-the-loop)
* **Media Processing via Build Extensions**: Workflows that process video using FFmpeg or convert documents to PDF using LibreOffice by installing system dependencies via Trigger.dev's `aptGet` build extension.
  [FFmpeg Video Processing](https://trigger.dev/docs/guides/examples/ffmpeg-video-processing)
* **Realtime Progress Streaming**: A Next.js application that evaluates multiple LLM models or imports large CSVs and streams progress updates back to the frontend using Trigger.dev's Realtime React hooks.
  [Next.js Batch LLM Evaluator](https://trigger.dev/docs/guides/example-projects/batch-llm-evaluator)

### 4. Developer Friction Points

* **`maxDuration` Configuration Errors**: Developers frequently encounter build or runtime errors when they forget to set the `maxDuration` in `trigger.config.ts` or set it to a value lower than the required 5 seconds. (See [Issue #1624](https://github.com/triggerdotdev/trigger.dev/issues/1624))
* **Lifecycle Hook Type Incompatibilities**: In v4, developers often face TypeScript errors stating "Types of parameters 'payload' and 'payload' are incompatible" when defining `onSuccess` or `onFailure` hooks on tasks with complex schemas. (See [Issue #2188](https://github.com/triggerdotdev/trigger.dev/issues/2188))
* **Separating Config Definition and Export**: Attempting to define `defineConfig` as a variable and exporting it separately in `trigger.config.ts` leads to confusing build failures, as the compiler expects a direct default export. (See [Issue #2080](https://github.com/triggerdotdev/trigger.dev/issues/2080))
* **Infinite Loops with Cached Sub-tasks**: When a parent task uses `batchTriggerAndWait` to trigger multiple child tasks that are cached, the parent task can sometimes hang indefinitely without completing. (See [Issue #1957](https://github.com/triggerdotdev/trigger.dev/issues/1957))

### 5. Evaluation Ideas

* Implement a multi-step background job that triggers three sub-tasks using `batchTriggerAndWait` and aggregates their outputs.
* Build a task that pauses execution using `wait.forToken()` until an external webhook callback completes the token.
* Configure a project with a custom `trigger.config.ts` that includes a global `maxDuration` and a specific retry policy for a flaky API task.
* Create an AI workflow task that handles cancellation gracefully by wiring the `onCancel` hook to an `AbortSignal` passed to a streaming LLM request.
* Implement a multi-tenant queue configuration that limits task concurrency strictly to one per user ID.
* Set up a TypeScript task that utilizes the `pythonExtension` to execute a Python data processing script and return the result.
* Build a Next.js API route that triggers a long-running data import task and streams the completion percentage to the frontend using the Realtime API.

### 6. Sources

1. [Trigger.dev LLMs Full Text](https://trigger.dev/llms-full.txt) - High-level overview, architecture, and core features of the platform.
2. [Trigger.dev Docs LLMs Index](https://trigger.dev/docs/llms.txt) - Complete index of all official documentation pages and guides.
3. [Trigger.dev Quick Start](https://trigger.dev/docs/quick-start.md) - Step-by-step instructions for initializing and running a Trigger.dev project.
4. [Tasks Overview](https://trigger.dev/docs/tasks/overview.md) - Detailed API documentation for defining tasks, configuring retries, and using lifecycle hooks.
5. [Wait Overview](https://trigger.dev/docs/wait.md) - Explanation of the `wait` primitives for pausing tasks without billing compute.
6. [AI Agents Overview](https://trigger.dev/docs/guides/ai-agents/overview.md) - Representative real-world use cases and templates for AI agent workflows.
7. [Trigger.dev GitHub Issues](https://github.com/triggerdotdev/trigger.dev/issues) - Used to mine developer friction points (specifically issues #1624, #2188, #2080, and #1957).   
  
### 7. Integration
*   **Trigger.dev**: A `project_ref` and a `TRIGGER_SECRET_KEY` are required to set up the project.
