### 1. Library Overview
*   **Description**: Composio is "The Skill Layer of AI," providing over 1000+ prebuilt toolkits (Slack, GitHub, Gmail, Notion, HubSpot, etc.) that enable AI agents to perform complex, authenticated actions across the web. It abstracts away the complexity of OAuth, API key management, and tool schema formatting for various LLM frameworks.
*   **Ecosystem Role**: It acts as a middleware/integration layer between AI agents (built with OpenAI, Claude, LangChain, CrewAI, etc.) and third-party software applications. It supports both native SDK integrations and the Model Context Protocol (MCP).
*   **Project Setup**:
    *   **Python**: `pip install composio` (plus provider-specific packages like `composio-openai`).
    *   **TypeScript**: `npm install @composio/core` (plus provider-specific packages like `@composio/openai`).
    *   **Configuration**: Requires a `COMPOSIO_API_KEY` from the [Composio Dashboard](https://platform.composio.dev/settings).
### 2. Core Primitives & APIs
*   **Users & Sessions**: Sessions are the primary entry point, scoping tools and connections to a specific `user_id`.
    *   [Users & Sessions Documentation](https://docs.composio.dev/docs/users-and-sessions)
*   **Meta Tools**: Instead of loading hundreds of tools into context, Composio provides system-level tools for discovery (`SEARCH_TOOLS`), authentication (`MANAGE_CONNECTIONS`), and execution (`MULTI_EXECUTE_TOOL`).
    *   [Meta Tools Reference](https://docs.composio.dev/reference/meta-tools)
*   **Workbench**: A persistent, sandboxed Python environment for bulk data processing and offloading large tool responses.
    *   [Workbench Documentation](https://docs.composio.dev/docs/workbench)
*   **Triggers**: Event-driven payloads (webhooks or polling) that allow agents to react to external app events (e.g., a new Slack message).
    *   [Triggers Documentation](https://docs.composio.dev/docs/triggers)
**Code Example (Native SDK - Python):**
```python
from composio import Composio
from composio_openai import OpenAIProvider
# Initialize with provider
composio = Composio(provider=OpenAIProvider())
# Create a session for a user
session = composio.create(user_id="user_123")
# Get meta tools for the agent
tools = session.tools()
# Tools are now ready to be passed to an OpenAI agent
# The agent will call COMPOSIO_SEARCH_TOOLS to find app-specific tools at runtime
```
**Code Example (Manual Auth - TypeScript):**
```typescript
import { Composio } from "@composio/core";
const composio = new Composio({ apiKey: "your_api_key" });
const session = await composio.create("user_123");
// Manually trigger an OAuth flow for GitHub
const connectionRequest = await session.authorize("github");
console.log("Connect here:", connectionRequest.redirectUrl);
// Wait for the user to complete authentication
const connectedAccount = await connectionRequest.waitForConnection();
```
### 3. Real-World Use Cases & Templates
*   **Workplace Search Agent**: A single agent querying across GitHub, Slack, Gmail, and Notion to synthesize answers with citations.
    *   [Cookbook: Workplace Search](https://docs.composio.dev/cookbooks/workplace-search)
*   **Morning Sweep Agent**: An autonomous script that runs daily to find PRs needing review, unanswered emails, and posts a digest to Slack.
    *   [Cookbook: Background Agent](https://docs.composio.dev/cookbooks/background-agent)
*   **PR Reviewer**: An AI agent that reads a repo's `CLAUDE.md`, reviews PR diffs against those rules, and posts feedback.
    *   [Cookbook: PR Review Agent](https://docs.composio.dev/cookbooks/pr-review-agent)
*   **Support Knowledge Agent**: An agentic RAG system triaging issues by pulling context from Notion, Datadog, and GitHub.
    *   [Cookbook: Support Agent](https://docs.composio.dev/cookbooks/support-agent)
### 4. Developer Friction Points
*   **Terminology Migration**: Significant changes between v1/v2 and v3 (e.g., "Actions" -> "Tools", "Integrations" -> "Auth Configs") can cause confusion when following older community tutorials.
*   **Session Immutability**: Sessions are fixed at creation; if you need to change toolkits or auth configs, you must create a new session rather than updating the existing one.
*   **Toolkit Versioning Defaults**: If `toolkit_versions` is not specified, the API defaults to the base version (`00000000_00`), which often contains significantly fewer tools than the "latest" version shown in the Dashboard UI.
*   **Auth Status Propagation**: Users sometimes report delays or failures in the auth status updating to "Connected" immediately after completing the OAuth flow.
### 5. Evaluation Ideas
*   **Simple**: Implement a script that stars a specific GitHub repository using a session-based agent.
*   **Simple**: Create a manual authentication flow that generates a Connect Link for Slack and waits for completion.
*   **Medium**: Build a multi-app agent that fetches the last 5 emails from Gmail and summarizes them into a specific Slack channel.
*   **Medium**: Use Schema Modifiers to hide specific sensitive arguments from a tool before passing it to the LLM.
*   **Complex**: Set up a Trigger that listens for new GitHub issues and uses the Workbench to run a Python script that analyzes the issue sentiment and labels it.
*   **Complex**: Implement a "Morning Sweep" agent that handles a session spanning 4+ toolkits, managing multiple connected accounts for the same user (e.g., work vs. personal Gmail).
### 6. Integration
*   **Composio**: A `COMPOSIO_API_KEY` is required to use the Composio CLI or SDK.
*   **LLM API**: Because Composio provides a toolkit layer for AI agents, users may also need access to an LLM backend such as OpenAI.
### 7. Sources
1. [Composio Official Documentation](https://docs.composio.dev/getting-started/welcome): Primary source for APIs, concepts, and cookbooks.
2. [Composio llms-full.txt](https://docs.composio.dev/llms-full.txt): Comprehensive technical dump of all SDK instructions and terminology.
3. [Composio GitHub Repository](https://github.com/ComposioHQ/composio): Source for issue tracking, community discussions, and version history.
4. [Composio Blog](https://composio.dev/blog): Insights on best practices for building AI tools and agentic workflows.
5. [Model Context Protocol (MCP)](https://modelcontextprotocol.io): Reference for Composio's MCP implementation.

