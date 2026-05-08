# Foundry Agent Setup Guide

This guide walks through deploying the **Store Intelligence Foundry Prompt Agent** — an Azure AI Foundry agent that orchestrates the three Fabric Data Agents (Sales, Inventory, Labor).

---

## Prerequisites

| Requirement | Details |
|---|---|
| Azure subscription | With Contributor access |
| Azure AI Foundry project | Created in [Azure AI Foundry portal](https://ai.azure.com) |
| Model deployment | `gpt-4o` (or equivalent) deployed in the Foundry project |
| Fabric workspace | With `lh_retaildata` Lakehouse and SQL views created (see main SETUP_GUIDE.md) |
| Fabric Data Agents | Sales, Inventory, Labor agents created and published |
| Service Principal | App registration with Fabric API permissions |
| Python 3.10+ | For local testing |

---

## Phase 1: Create Azure AI Foundry Project

1. Go to [Azure AI Foundry](https://ai.azure.com) → **+ Create project**
2. Select your subscription and resource group
3. Name the project (e.g. `store-intelligence`)
4. Choose a region with GPT-4o availability
5. After creation, copy the **Project endpoint** from the project overview page

## Phase 2: Deploy a Model

1. In the Foundry project, go to **Models + endpoints** → **+ Deploy model**
2. Deploy `gpt-4o` (or your preferred model)
3. Note the **Deployment name** (default: `gpt-4o`)

## Phase 3: Get Fabric Data Agent Endpoints

For each of the three Fabric Data Agents (Sales, Inventory, Labor):

1. Open the agent in Microsoft Fabric
2. Click **Publish** (if not already published)
3. Copy the published endpoint URL

> **Note:** The exact endpoint format depends on Fabric's agent API. Update the URLs in `.env` once you have them.

## Phase 4: Configure Service Principal

1. In Entra ID → **App registrations** → create or reuse a registration
2. Add a client secret and note it
3. Grant the service principal access to the Fabric workspace:
   - Fabric workspace → **Manage access** → add the SP with **Contributor** role
4. Note the **Tenant ID**, **Client ID**, and **Client Secret**

## Phase 5: Configure Environment

```bash
cd foundry_agent
cp .env.template .env
```

Edit `.env` with your actual values:

| Variable | Source |
|---|---|
| `PROJECT_ENDPOINT` | Foundry project overview page |
| `MODEL_DEPLOYMENT_NAME` | Foundry model deployment name |
| `FABRIC_SALES_AGENT_ENDPOINT` | Published Fabric Sales Agent URL |
| `FABRIC_INVENTORY_AGENT_ENDPOINT` | Published Fabric Inventory Agent URL |
| `FABRIC_LABOR_AGENT_ENDPOINT` | Published Fabric Labor Agent URL |
| `FABRIC_TENANT_ID` | Entra ID tenant |
| `FABRIC_CLIENT_ID` | App registration client ID |
| `FABRIC_CLIENT_SECRET` | App registration secret value |

## Phase 6: Install & Run Locally

```bash
pip install -r requirements.txt
python app.py
```

Make sure you're authenticated for Foundry (the agent uses `DefaultAzureCredential`):

```bash
az login
```

### Test Questions

```
You: What were the top 5 stores by revenue last week?
You: Show me all chronic OOS products in the West region
You: Give me a store health check for store STR-001
You: Which stores are understaffed on morning shifts?
You: quit
```

## Phase 7: Deploy to Foundry (Optional)

To deploy as a hosted Prompt Agent in Azure AI Foundry:

1. In the Foundry portal, go to **Agents** → **+ New agent**
2. Select your deployed model
3. Paste the system prompt from `app.py` (`SYSTEM_PROMPT`)
4. Add the three tool functions manually in the Foundry UI (matching the schemas in `tools.py`)
5. Test in the Foundry playground

> For programmatic deployment, the `azure-ai-projects` SDK handles agent creation automatically when you run `app.py`.

---

## Architecture

```
User
  │
  ▼
Foundry Prompt Agent (GPT-4o)
  │  ┌──────────────┐
  ├─▶│ Sales Agent   │──▶ Fabric Lakehouse (vw_sales_summary)
  │  └──────────────┘
  │  ┌──────────────┐
  ├─▶│ Inventory    │──▶ Fabric Lakehouse (vw_inventory_health,
  │  │ Agent        │    vw_osa_daily, vw_oos_classification)
  │  └──────────────┘
  │  ┌──────────────┐
  └─▶│ Labor Agent  │──▶ Fabric Lakehouse (vw_labor_coverage)
     └──────────────┘
```

## Troubleshooting

| Issue | Fix |
|---|---|
| `Failed to acquire Fabric token` | Verify FABRIC_TENANT_ID, CLIENT_ID, CLIENT_SECRET in `.env`. Ensure the SP has Fabric API permissions. |
| `DefaultAzureCredential` error | Run `az login` or set AZURE_CLIENT_ID/SECRET/TENANT_ID env vars. |
| `404` from Fabric agent endpoint | Confirm the agent is published and the endpoint URL is correct. |
| `Run failed` | Check the error message — usually a tool execution failure. Verify Fabric agent connectivity. |
