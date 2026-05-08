# Databricks Genie + Foundry Setup Guide

This guide walks through deploying the **Store Intelligence** solution on Databricks, using **Genie Spaces** as domain-specific data agents and **Azure AI Foundry** as the orchestrator.

---

## Prerequisites

| Requirement | Details |
|---|---|
| Databricks workspace | With Unity Catalog enabled |
| SQL warehouse | Pro or Serverless, with CAN USE permission |
| Azure subscription | With Contributor access |
| Azure AI Foundry project | With a deployed model (e.g. gpt-4o) |
| Python 3.10+ | For local testing |

---

## Phase 1: Set Up Unity Catalog

1. Open your Databricks workspace
2. Create a catalog (or use an existing one):
   ```sql
   CREATE CATALOG IF NOT EXISTS store_intel;
   ```
3. Create the `retail` schema:
   ```sql
   CREATE SCHEMA IF NOT EXISTS store_intel.retail;
   ```
4. Load the 13 source tables into `store_intel.retail.*` (use Databricks notebooks, Auto Loader, or COPY INTO)

> **Note:** Replace `${catalog}` with your catalog name (e.g. `store_intel`) in all SQL view files before running them.

## Phase 2: Create SQL Views

Run the view SQL files in order from `databricks_genie/sql/views/` in a Databricks SQL editor or notebook:

1. `vw_sales_summary.sql`
2. `vw_inventory_health.sql`
3. `vw_osa_daily.sql`
4. `vw_labor_coverage.sql`
5. `vw_oos_classification.sql` (depends on the first three views)

**SQL dialect changes from the Fabric version:**
- `CREATE OR REPLACE VIEW` (not `CREATE OR ALTER VIEW`)
- `DATE_SUB(CURRENT_DATE(), N)` (not `DATEADD(DAY, -N, CAST(GETDATE() AS DATE))`)
- `CURRENT_DATE()` / `CURRENT_TIMESTAMP()` (not `GETDATE()`)
- `CAST(x AS DOUBLE)` (not `CAST(x AS FLOAT)`)
- No `GO` statements

## Phase 3: Create Genie Spaces

You can create Genie Spaces either through the UI or the API.

### Option A: Databricks UI

For each of the three spaces (Sales, Inventory, Labor):

1. Go to **SQL** → **Genie Spaces** → **+ Create**
2. Name the space (e.g. "Store Intelligence — Sales")
3. Select your SQL warehouse
4. Add the relevant tables/views from `store_intel.retail.*`
5. Add **General Instructions** — copy the `text_instructions.content` from the corresponding JSON file in `databricks_genie/genie_spaces/`
6. Add **Example SQL Queries** — copy each `example_question_sqls` entry
7. Copy the **Space ID** from the URL (e.g. `https://<host>/sql/genie/<space_id>`)

### Option B: Genie API

Use the JSON files in `databricks_genie/genie_spaces/` with the Create Space API:

```bash
# Replace placeholders in the JSON first:
# - ${catalog} → your catalog name
# - <your-sql-warehouse-id> → your SQL warehouse ID
# - <username> → your Databricks username

# For each space:
curl -X POST "https://<DATABRICKS_HOST>/api/2.0/genie/spaces" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d @databricks_genie/genie_spaces/sales_space.json
```

> **Important:** The `serialized_space` field in the JSON must be stringified (escaped) before sending to the API. The JSON files contain the unescaped structure for readability — stringify the `serialized_space` value before the API call.

Record the three Space IDs returned.

## Phase 4: Create Foundry Project & Deploy Model

1. Go to [Azure AI Foundry](https://ai.azure.com) → **+ Create project**
2. Name the project (e.g. `store-intelligence-databricks`)
3. Deploy `gpt-4o` (or your preferred model)
4. Copy the **Project endpoint** and **Deployment name**

## Phase 5: Configure & Test Locally

```bash
cd databricks_genie/foundry_agent
cp .env.template .env
```

Fill in `.env`:

| Variable | Source |
|---|---|
| `PROJECT_ENDPOINT` | Foundry project overview page |
| `MODEL_DEPLOYMENT_NAME` | Foundry model deployment name |
| `DATABRICKS_HOST` | Databricks workspace URL (e.g. `https://adb-xxx.azuredatabricks.net`) |
| `DATABRICKS_TOKEN` | Databricks PAT (Settings → Developer → Access tokens) |
| `GENIE_SALES_SPACE_ID` | Sales Genie Space ID |
| `GENIE_INVENTORY_SPACE_ID` | Inventory Genie Space ID |
| `GENIE_LABOR_SPACE_ID` | Labor Genie Space ID |

Install and run:

```bash
pip install -r requirements.txt
az login   # for Foundry DefaultAzureCredential
python app.py
```

### Test Questions

```
You: What were the top 5 stores by revenue last week?
You: Show me all chronic OOS products
You: Which stores are understaffed on morning shifts?
You: Give me a full store health check for Store 42
You: quit
```

---

## Architecture

```
User
  │
  ▼
Foundry Hosted Agent (GPT-4o)
  │  ┌─────────────────┐
  ├─▶│ Sales Genie      │──▶ Unity Catalog (vw_sales_summary)
  │  │ Space             │
  │  └─────────────────┘
  │  ┌─────────────────┐
  ├─▶│ Inventory Genie  │──▶ Unity Catalog (vw_inventory_health,
  │  │ Space             │    vw_osa_daily, vw_oos_classification)
  │  └─────────────────┘
  │  ┌─────────────────┐
  └─▶│ Labor Genie      │──▶ Unity Catalog (vw_labor_coverage)
     │ Space             │
     └─────────────────┘
```

**Key difference from the Fabric version:** The Genie Conversation API is **asynchronous**. The Foundry agent's tool functions start a conversation, then poll with exponential backoff (1s → 2s → 4s, max 60s, timeout 5min) until the Genie Space returns a `COMPLETED` status.

---

## Rate Limits

The Genie Conversation API free tier supports **5 questions per minute per workspace**. Cross-domain queries (e.g. "store health check") call all 3 Genie Spaces, consuming 3 of those 5 QPM. For higher throughput, contact your Databricks account team.

## Production Auth

For production, replace the PAT with **OAuth M2M** (service principal):

1. Create a service principal in your Databricks account
2. Grant it access to the SQL warehouse and Unity Catalog data
3. Set `DATABRICKS_TOKEN` to the OAuth access token obtained via client credentials flow

See [OAuth for service principals (M2M)](https://docs.databricks.com/en/dev-tools/auth/oauth-m2m.html).

---

## Troubleshooting

| Issue | Fix |
|---|---|
| `401 Unauthorized` from Genie API | Verify `DATABRICKS_TOKEN` is valid and not expired. Regenerate PAT if needed. |
| `404 Not Found` on space | Confirm the Space ID is correct and the space exists. |
| `Genie query timed out` | The SQL warehouse may be starting up (cold start). Retry, or use an always-on warehouse. |
| `DefaultAzureCredential` error | Run `az login` or set `AZURE_CLIENT_ID`/`SECRET`/`TENANT_ID` env vars. |
| `Run failed` in Foundry | Check the error message — usually a tool execution failure. Verify Databricks connectivity. |
| Empty results from Genie | The Genie Space may need more instructions or example SQL. Refine in the Databricks UI. |
| Rate limit hit (429) | Reduce query frequency or request higher throughput from Databricks. |
