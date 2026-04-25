# Trigger.dev Benchmark Plan

### 1. Library Overview

* **Description**: Trigger.dev is an open-source platform for building AI agents and long-running background jobs in TypeScript. It allows developers to write standard async code that executes without serverless timeouts, managing retries, queues, monitoring, and elastic scaling automatically.
* **Ecosystem Role**: It serves as a modern, robust alternative to traditional message queues (like BullMQ, Celery, or RabbitMQ) and cron jobs. It integrates directly into modern full-stack TS frameworks (Next.js, Remix, Node.js) and is particularly well-suited for orchestrating AI workflows, media processing, and complex multi-step SaaS background jobs.
* **Project Setup**: 
  Trigger.dev is initialized directly into an existing project via the CLI:
  ```bash
  # Initialize Trigger.dev in an existing project
  npx trigger.dev@latest init
  
  # Start the dev server (watches the /trigger directory)
  npx trigger.dev@latest dev
  ```
  During initialization, it creates a `trigger.config.ts` file, a `/trigger` directory for task definitions, and requires adding a `TRIGGER_SECRET_KEY` to the local `.env` file.

### 2. Core Primitives & APIs

* **`task`**: The core primitive used to define a background job, its configuration (retries, timeouts, machine sizes), and its execution logic.
* **`tasks.trigger`**: The API used in the backend to invoke a task and pass a strongly-typed payload.
* **`logger`**: Built-in observability to emit logs, traces, and metadata that sync to the Trigger.dev dashboard.
* **Build Extensions**: Configurations in `trigger.config.ts` that modify the runtime environment (e.g., adding Python, FFmpeg binaries, or Prisma ORM).

**Basic Task Definition & Triggering:**
```typescript
import { task } from "@trigger.dev/sdk";

// 1. Define the task in the /trigger directory
export const simpleTask = task({
  id: "simple-task",
  run: async (payload: { message: string }) => {
    console.log(payload.message);
    return { success: true };
  },
});
```
```typescript
import { tasks } from "@trigger.dev/sdk";
import type { simpleTask } from "./trigger/example";

// 2. Trigger the task from your application backend
const handle = await tasks.trigger<typeof simpleTask>("simple-task", { 
  message: "Hello from my app!" 
});
```

**Advanced Usage (Retries, Context, and Logging):**
```typescript
import { task, logger } from "@trigger.dev/sdk";

export const advancedTask = task({
  id: "advanced-task",
  retry: {
    maxAttempts: 3,
    factor: 2,
    minTimeoutInMs: 1000,
  },
  run: async (payload: { userId: string }, { ctx }) => {
    logger.info("Task started", { attempt: ctx.run.attempt.number });
    
    // Context (ctx) provides metadata about the execution environment
    if (ctx.run.attempt.number === 1) {
      throw new Error("Simulated transient error");
    }
    
    return { status: "completed", environment: ctx.environment.slug };
  },
});
```

* **Links to Documentation:**
  * [Tasks Overview](https://trigger.dev/docs/tasks/overview)
  * [Triggering Tasks](https://trigger.dev/docs/triggering)
  * [Build Extensions](https://trigger.dev/docs/config/extensions/overview)

### 3. Real-World Use Cases & Templates

* **AI Agents & Prompt Chaining**: Trigger.dev is heavily utilized for long-running LLM operations where serverless timeouts would typically fail. Developers use `wait.forToken` to pause execution for human-in-the-loop approvals before continuing a prompt chain.
* **Media Processing**: Leveraging the `ffmpeg` build extension, developers can transcode video or audio natively within a TypeScript task without managing external compute clusters.
* **Document Generation**: Using the `puppeteer` or `libreoffice` build extensions to scrape web pages or generate complex PDFs asynchronously.
* **Common Integration Patterns**:
  * **Realtime UI Updates**: Using Trigger.dev's React hooks (`useEventDetails` or Streams v2) to stream task progress to the frontend.
  * **Batch Processing**: Using `batch.triggerAndWait` to execute large ETL pipelines or process bulk CSV data efficiently.

### 4. Developer Friction Points

* **Debugging DX in v3/v4**: Developers struggle to debug tasks locally because the Trigger.dev dev server spawns each task in a separate Node.js process. This makes it difficult to attach an IDE debugger (like VSCode) to catch specific breakpoints, especially when dealing with concurrent webhook-triggered tasks. ([Issue #1206](https://github.com/triggerdotdev/trigger.dev/issues/1206))
* **Build Extension & ORM Conflicts**: Integrating complex tools like Prisma (specifically features like `typedSql`) into the Trigger.dev build process can lead to "Unknown type" errors or deployment failures due to how Trigger.dev bundles code. ([Issue #2248](https://github.com/triggerdotdev/trigger.dev/issues/2248))
* **Realtime API Payload Limits**: The Realtime API occasionally fails to return runs or drops data when task payloads or outputs are too large, forcing developers to migrate to the newer Streams v2 API for heavy data streaming. ([Issue #1451](https://github.com/triggerdotdev/trigger.dev/issues/1451))

### 5. Evaluation Ideas

1. Initialize a Trigger.dev project and create a basic "Hello World" background task.
2. Implement a scheduled task (cron job) that fetches external API data and logs the result every hour.
3. Create a task with complex retry logic (custom backoff intervals) that handles and recovers from simulated transient network failures.
4. Set up a Next.js frontend that uses Trigger.dev Realtime hooks to display the live progress of a background job.
5. Build an AI prompt-chaining workflow that uses `wait.forToken` to pause the task for a human-in-the-loop approval.
6. Implement a media processing task using the FFmpeg build extension to transcode a mock video file.
7. Configure a task with a custom Prisma build extension, ensuring database migrations run correctly inside the Trigger.dev environment.
8. Implement a multi-tenant batch processing job using `batch.triggerAndWait` with strict concurrency limits per tenant.

### 6. Sources

1. [https://trigger.dev/llms.txt](https://trigger.dev/llms.txt) - Trigger.dev high-level LLM overview
2. [https://trigger.dev/llms-full.txt](https://trigger.dev/llms-full.txt) - Trigger.dev full documentation for LLMs and technical details
3. [https://trigger.dev/docs](https://trigger.dev/docs) - Official Documentation Home
4. [https://trigger.dev/docs/quick-start](https://trigger.dev/docs/quick-start) - Quick Start & Setup Guide
5. [https://trigger.dev/docs/writing-tasks-introduction](https://trigger.dev/docs/writing-tasks-introduction) - Writing Tasks Overview
6. [https://github.com/triggerdotdev/trigger.dev/issues](https://github.com/triggerdotdev/trigger.dev/issues) - GitHub Issues (used to identify developer friction points)   
  
### 7. Integration
*   **Trigger.dev**: A `project_ref` and a `TRIGGER_SECRET_KEY` are required to set up the project.
