# Store Intelligence — Setup Guide

Step-by-step instructions to deploy the solution in Microsoft Fabric + Copilot Studio.

---

## Prerequisites

- Microsoft Fabric workspace with the `lh_retaildata` Lakehouse (already exists)
- Fabric capacity (F2 or higher for Data Agents)
- Copilot Studio license (included with M365 Copilot or standalone)
- Permissions: Workspace Admin or Member on the Fabric workspace

---

## Phase 1: Create Lakehouse Views

Run each SQL file in the **Fabric SQL analytics endpoint** for `lh_retaildata`.

1. Open your Fabric workspace → click on the **SQL analytics endpoint** for `lh_retaildata`
2. Click **New SQL query**
3. Run each view script in order:

| # | File | View Created |
|---|------|-------------|
| 1 | [`sql/views/vw_sales_summary.sql`](sql/views/vw_sales_summary.sql) | `retail.vw_sales_summary` |
| 2 | [`sql/views/vw_inventory_health.sql`](sql/views/vw_inventory_health.sql) | `retail.vw_inventory_health` |
| 3 | [`sql/views/vw_osa_daily.sql`](sql/views/vw_osa_daily.sql) | `retail.vw_osa_daily` |
| 4 | [`sql/views/vw_labor_coverage.sql`](sql/views/vw_labor_coverage.sql) | `retail.vw_labor_coverage` |
| 5 | [`sql/views/vw_oos_classification.sql`](sql/views/vw_oos_classification.sql) | `retail.vw_oos_classification` |

> **Note:** `vw_oos_classification` depends on `vw_osa_daily` and `vw_sales_summary`, so run it last.

4. Verify each view by running `SELECT TOP 10 * FROM retail.<view_name>`

---

## Phase 2: Create Fabric Data Agents

Repeat these steps **three times** — once for each agent (Sales, Inventory, Labor).

### 2.1 Create the Agent

1. In your Fabric workspace, click **+ New item** → search for **"Data Agent"** → select it
2. Name the agent (e.g., `Sales Agent`, `Inventory Agent`, `Labor Agent`)
3. Click **Create**

### 2.2 Add Data Sources

In the agent configuration:

1. Click **Add data source** → select the `lh_retaildata` SQL analytics endpoint
2. Select the specific tables and views for that agent:

| Agent | Tables & Views to Add |
|-------|----------------------|
| **Sales Agent** | `vw_sales_summary`, `orders`, `order_lines`, `products`, `product_categories`, `regions`, `forecasts`, `stores` |
| **Inventory Agent** | `vw_inventory_health`, `vw_osa_daily`, `vw_oos_classification`, `inventories`, `products`, `product_categories`, `warehouses`, `demand_signals`, `visual_osa_daily`, `stores`, `regions` |
| **Labor Agent** | `vw_labor_coverage`, `associate_assignments`, `stores`, `regions` |

### 2.3 Add Instructions

1. In the agent config, find the **Instructions** section
2. Copy the contents from the corresponding instructions file:
   - Sales: [`agents/sales_agent/instructions.md`](agents/sales_agent/instructions.md)
   - Inventory: [`agents/inventory_agent/instructions.md`](agents/inventory_agent/instructions.md)
   - Labor: [`agents/labor_agent/instructions.md`](agents/labor_agent/instructions.md)
3. Paste into the Instructions field

### 2.4 Add Example Queries

1. In the agent config, find the **Examples** section
2. Add Q&A pairs from the corresponding example queries file:
   - Sales: [`agents/sales_agent/example_queries.sql`](agents/sales_agent/example_queries.sql)
   - Inventory: [`agents/inventory_agent/example_queries.sql`](agents/inventory_agent/example_queries.sql)
   - Labor: [`agents/labor_agent/example_queries.sql`](agents/labor_agent/example_queries.sql)
3. For each example: paste the **question** (the comment) and the **SQL** (the query) as a Q&A pair

### 2.5 Test Each Agent

1. Use the built-in **Test** panel in the Data Agent editor
2. Try at least 5 queries per agent from the example files
3. Verify the generated SQL is correct and returns expected results
4. **Publish** the agent once testing passes

---

## Phase 3: Set Up Copilot Studio Orchestrator

### 3.1 Create the Agent

1. Go to [Copilot Studio](https://copilotstudio.microsoft.com)
2. Click **Create** → **New agent**
3. Name it **"Store Intelligence Assistant"**
4. In the **Instructions** field, paste the system prompt from [`copilot_studio/orchestrator_instructions.md`](copilot_studio/orchestrator_instructions.md)

### 3.2 Connect Fabric Data Agents as Actions

For each of the 3 Fabric Data Agents:

1. In Copilot Studio, go to **Actions** → **Add an action**
2. Select **Fabric Data Agent** connector
3. Choose your Fabric workspace → select the published Data Agent
4. Repeat for all 3 agents (Sales, Inventory, Labor)

### 3.3 Configure Topics (Optional but Recommended)

Create custom topics for the three common scenarios:

| Topic | Trigger Phrases | Config File |
|-------|----------------|-------------|
| Store Health Check | "How is store X doing?", "Store overview" | [`copilot_studio/topics/store_health_check.md`](copilot_studio/topics/store_health_check.md) |
| Morning Briefing | "Morning briefing", "Daily summary" | [`copilot_studio/topics/morning_briefing.md`](copilot_studio/topics/morning_briefing.md) |
| Risk Summary | "What should I worry about?", "Any risks?" | [`copilot_studio/topics/risk_summary.md`](copilot_studio/topics/risk_summary.md) |

For each topic:
1. Go to **Topics** → **Add a topic** → **From blank**
2. Add the trigger phrases from the config file
3. In the topic flow, add a **Message** node that calls the appropriate agent actions and formats the response per the template

### 3.4 Configure Greeting

1. Go to **Topics** → **System** → **Greeting**
2. Replace the default greeting with the one from [`copilot_studio/orchestrator_instructions.md`](copilot_studio/orchestrator_instructions.md) (Greeting Message section)

### 3.5 Publish to Microsoft Teams

1. In Copilot Studio, go to **Channels** → **Microsoft Teams**
2. Click **Turn on Teams**
3. Click **Open in Teams** to test
4. To make available org-wide: go to **Availability** → **Show to everyone in my org**

---

## Phase 4: Testing Checklist

### Per-Agent Tests (run in Fabric Data Agent test panel)

**Sales Agent:**
- [ ] "Total revenue last 7 days"
- [ ] "Top 10 products by revenue this month"
- [ ] "Daily revenue trend for [region]"
- [ ] "Compare this week vs last week by region"
- [ ] "Expedited orders breakdown"

**Inventory Agent:**
- [ ] "Products with inventory risk flags"
- [ ] "On-shelf availability by store this week"
- [ ] "Which products are most often off-shelf?"
- [ ] "Perishable products with lead time issues"
- [ ] "Lowest OSA stores"
- [ ] "Show me all out-of-stock products"
- [ ] "Which products are truly out of stock?"
- [ ] "Show me phantom out-of-stocks"
- [ ] "Show me chronic out-of-stock problems"
- [ ] "OOS summary by store"

**Labor Agent:**
- [ ] "Headcount by store"
- [ ] "Understaffed stores vs average"
- [ ] "Shift coverage for [store]"
- [ ] "Stores with single-associate shifts"
- [ ] "Role distribution across stores"

### Orchestrator Tests (run in Copilot Studio / Teams)

- [ ] "How is Store 42 doing?" → should query all 3 agents
- [ ] "Morning briefing" → should return cross-domain summary
- [ ] "Any risks today?" → should surface inventory + staffing risks
- [ ] "Which stores have stockout risks?" → should route to Inventory Agent only
- [ ] "Are any stores understaffed?" → should route to Labor Agent only
- [ ] "Revenue trend for Southeast" → should route to Sales Agent only

---

## Folder Structure

```
StoreIntelligence/
├── sql/views/
│   ├── vw_sales_summary.sql          # Phase 1
│   ├── vw_inventory_health.sql
│   ├── vw_osa_daily.sql
│   ├── vw_labor_coverage.sql
│   └── vw_oos_classification.sql     # Depends on vw_osa_daily + vw_sales_summary
├── agents/
│   ├── sales_agent/
│   │   ├── instructions.md            # Phase 2 — agent system prompts
│   │   └── example_queries.sql        # Phase 2 — example Q&A pairs
│   ├── inventory_agent/
│   │   ├── instructions.md
│   │   └── example_queries.sql
│   └── labor_agent/
│       ├── instructions.md
│       └── example_queries.sql
├── copilot_studio/
│   ├── orchestrator_instructions.md   # Phase 3 — Copilot Studio config
│   └── topics/
│       ├── store_health_check.md
│       ├── morning_briefing.md
│       └── risk_summary.md
└── SETUP_GUIDE.md                     # This file
```
