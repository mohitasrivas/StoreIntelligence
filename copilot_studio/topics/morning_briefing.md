# Topic: Morning Briefing

## Trigger Phrases
- "Morning briefing"
- "What happened yesterday?"
- "Daily summary"
- "Give me today's briefing"
- "Start of day report"

## Behavior
When triggered, the orchestrator should:

1. **Query all three agents** for yesterday's data:
   - **Sales Agent**: "Show total revenue, order count, top 3 regions by revenue, and top 3 products by units sold for yesterday."
   - **Inventory Agent**: "Show overall on-shelf availability rate, count of products with off-shelf flags, and any inventory risk flags for yesterday."
   - **Labor Agent**: "Show total associate headcount across all stores, any stores with single-associate shifts, and overall avg orders managed per associate."
2. **Synthesize** into a concise briefing:

### Response Template

> ## Morning Briefing — [Yesterday's Date]
>
> ### 📊 Sales Snapshot
> - **Total revenue**: $X across X orders
> - **Top regions**: [Region A: $X, Region B: $X, Region C: $X]
> - **Top products**: [Product A: X units, Product B: X units, Product C: X units]
>
> ### 📦 Inventory Snapshot
> - **Overall OSA rate**: X%
> - **Products off-shelf**: X products across X stores
> - **Inventory risk flags**: X products flagged
>
> ### 👥 Staffing Snapshot
> - **Total associates on shift**: X across X stores
> - **Coverage risks**: X stores with single-associate shifts
> - **Avg productivity**: X orders/associate
>
> ### 🔴 Items Needing Attention
> - [Top 3 action items ranked by severity]
