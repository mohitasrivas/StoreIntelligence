# Topic: Store Health Check

## Trigger Phrases
- "How is store X doing?"
- "Store health check for X"
- "Give me an overview of store X"
- "What's happening at store X?"
- "Store X status"

## Behavior
When triggered, the orchestrator should:

1. **Identify the store** from the user's message (store name or ID).
2. **Query all three agents** in parallel:
   - **Sales Agent**: "Show revenue, order count, units sold, and top categories for the region containing store [X] for the last 7 days."
   - **Inventory Agent**: "Show on-shelf availability rate and any off-shelf products for store [X] for the last 7 days."
   - **Labor Agent**: "Show headcount, shift breakdown, and any coverage risks for store [X]."
3. **Synthesize** into a unified response:

### Response Template

> ## Store Health Check: [Store Name]
> *Data as of [date], last 7 days*
>
> ### 📊 Sales (Region: [Region Name])
> - **Revenue**: $X | **Orders**: X | **Units sold**: X
> - **Avg basket size**: $X
> - **Top categories**: [list]
>
> ### 📦 Inventory & Shelf Availability
> - **On-shelf availability**: X%
> - **Products off-shelf**: [count] ([list top 3])
> - **Inventory risks**: [any risk flags from vw_inventory_health]
>
> ### 👥 Staffing
> - **Headcount**: X associates
> - **Shift coverage**: [Morning: X, Afternoon: X, Evening: X]
> - **Coverage risks**: [any single-associate shifts]
>
> ### ⚡ Recommended Actions
> - [Action items based on findings]
