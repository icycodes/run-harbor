### 1. Library Overview
*   **Description**: Scalekit is an enterprise authentication platform specifically designed for B2B SaaS and AI applications. It provides a comprehensive set of tools for implementing Single Sign-On (SSO) via SAML and OIDC, SCIM provisioning, multi-tenant organization management, and specialized authentication for AI agents (Agent Auth and MCP Auth).
*   **Ecosystem Role**: Scalekit acts as a dedicated identity layer that can either replace a traditional auth system (Full Stack Auth) or coexist with existing providers like Auth0, AWS Cognito, or Firebase (Modular SSO). It bridges the gap between modern application development and complex enterprise identity requirements.
*   **Project Setup**:
    1.  **Account Creation**: Sign up at [app.scalekit.com](https://app.scalekit.com/ws/signup) to get an environment URL and API credentials.
    2.  **Environment Variables**:
        ```bash
        SCALEKIT_ENVIRONMENT_URL=https://<your-subdomain>.scalekit.com
        SCALEKIT_CLIENT_ID=skc_...
        SCALEKIT_CLIENT_SECRET=sksec_...
        ```
    3.  **SDK Installation**:
        *   **Node.js**: `npm install @scalekit-sdk/node`
        *   **Python**: `pip install scalekit-sdk-python`
        *   **Go**: `go get -u github.com/scalekit-inc/scalekit-sdk-go`
    4.  **Initialization**:
        ```python
        from scalekit import ScalekitClient
        import os
        scalekit = ScalekitClient(
            env_url=os.getenv('SCALEKIT_ENVIRONMENT_URL'),
            client_id=os.getenv('SCALEKIT_CLIENT_ID'),
            client_secret=os.getenv('SCALEKIT_CLIENT_SECRET')
        )
        ```
### 2. Core Primitives & APIs
*   **`ScalekitClient`**: The central entry point for all SDK operations.
*   **`authentication.get_authorization_url()`**: Generates the URL to redirect users for SSO login.
    *   [Documentation](https://docs.scalekit.com/authenticate/sso/add-modular-sso/#1-generate-authorization-url)
    ```python
    auth_url = scalekit.authentication.get_authorization_url(
        redirect_uri="https://app.com/callback",
        state="random_state_string",
        organization_id="org_123" # Or connection_id
    )
    ```
*   **`authentication.authenticate_with_code()`**: Exchanges the authorization code received at the callback for tokens and user profile.
    *   [Documentation](https://docs.scalekit.com/authenticate/fsa/complete-login/#2-exchange-authorization-code-for-tokens)
    ```python
    result = scalekit.authentication.authenticate_with_code(
        code=code,
        redirect_uri="https://app.com/callback"
    )
    user = result.user
    tokens = result.tokens
    ```
*   **`organization.list_organizations()`**: Manages multi-tenant tenants.
    *   [Documentation](https://docs.scalekit.com/reference/api/organizations/list-organizations/)
*   **`directory.list_directories()`**: Manages SCIM and directory sync connections.
    *   [Documentation](https://docs.scalekit.com/reference/api/directories/list-directories/)
*   **`mcp.authenticate()`**: Specialized primitives for Model Context Protocol (MCP) authentication.
    *   [Documentation](https://docs.scalekit.com/authenticate/mcp/quickstart/)
### 3. Real-World Use Cases & Templates
*   **Enterprise SSO Integration**: Adding SAML/OIDC support for enterprise customers (Okta, Azure AD) without rewriting the core auth logic.
*   **SCIM User Provisioning**: Automatically syncing user accounts from an enterprise Identity Provider (IdP) to the SaaS application.
*   **AI Agent Authorization (Agent Auth)**: Providing AI agents with a secure "token vault" to access third-party services (Gmail, Slack) on behalf of users.
*   **Remote MCP Server Auth**: Securing remote MCP servers using OAuth 2.1 and Dynamic Client Registration.
*   **Multi-tenant Admin Portal**: Embedding a Scalekit-hosted portal for customers to manage their own SSO and SCIM settings.
### 4. Developer Friction Points
*   **OAuth State Management**: Correctly implementing CSRF protection by storing and validating the `state` parameter across redirects ([Discussion](https://docs.scalekit.com/authenticate/fsa/complete-login/#1-validate-the-state-parameter-recommended)).
*   **Webhook Verification**: Securely handling and verifying signatures for SCIM events (user created/deleted) to ensure they originate from Scalekit.
*   **Token Mapping**: Mapping Scalekit's standardized user profile and roles to an application's internal database schema, especially in "Modular SSO" mode.
### 5. Evaluation Ideas
*   **Basic SSO**: Implement a login redirect and callback handler using Scalekit in a web framework (e.g., Express or FastAPI).
*   **Multi-tenancy**: Create a script to programmatically create an organization and set up an SSO connection for a specific domain.
*   **SCIM Webhook**: Build a webhook endpoint that listens for SCIM "user.created" events and updates a local database.
*   **MCP Security**: Configure a remote MCP server to require Scalekit OAuth 2.1 authentication before allowing tool execution.
*   **Agent Vault**: Implement a flow where an AI agent requests a token from Scalekit's Agent Auth vault to call the Slack API.
*   **Modular Integration**: Configure Scalekit as a custom OIDC provider in an existing Auth0 or AWS Cognito setup.
### 6. Integration
*   **Scalekit**: Environment variables `SCALEKIT_ENVIRONMENT_URL`, `SCALEKIT_CLIENT_ID`, and `SCALEKIT_CLIENT_SECRET` are required.
### 7. Sources
1.  [Scalekit Official Documentation](https://docs.scalekit.com/): Primary source for all product details and guides.
2.  [Scalekit llms.txt](https://docs.scalekit.com/llms.txt): Structured overview for LLM consumption.
3.  [Scalekit Python SDK GitHub](https://github.com/scalekit-inc/scalekit-sdk-python): API reference and code examples for Python.
4.  [Scalekit Node.js SDK GitHub](https://github.com/scalekit-inc/scalekit-sdk-node): API reference and code examples for Node.js.
5.  [Scalekit MCP Server](https://github.com/scalekit-inc/mcp): Source code for the Scalekit MCP implementation.
6.  [Scalekit Demo Video](https://www.youtube.com/watch?v=098_9blgM90): Overview of B2B and AI authentication features.