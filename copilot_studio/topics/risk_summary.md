# Topic: Risk Summary

## Trigger Phrases
- "What should I worry about?"
- "Any risks today?"
- "Risk summary"
- "Show me problems"
- "What needs attention?"
- "Alert summary"

## Behavior
When triggered, the orchestrator should:

1. **Query all three agents** focusing on risk indicators:
   - **Sales Agent**: "Show any regions where last 7 days revenue declined more than 10% compared to the prior 7 days."
   - **Inventory Agent**: "Show products with inventory risk flags (not OK), and stores with on-shelf availability below 90% in the last 7 days."
   - **Labor Agent**: "Show stores with single-associate shifts and stores with headcount below the average for their store type."
2. **Synthesize** into a prioritized risk list:

### Response Template

> ## Risk Summary — [Date]
>
> ### 🔴 Critical
> - [Highest-severity items: stockouts on high-demand products, stores with no shift coverage, major revenue drops]
>
> ### 🟡 Warning
> - [Medium-severity items: OSA below 90%, perishable lead-time risks, staffing below average]
>
> ### 🟢 Monitoring
> - [Lower-severity items worth tracking: minor revenue dips, single-associate shifts in low-traffic periods]
>
> ### ⚡ Recommended Actions
> 1. [Most urgent action]
> 2. [Second priority]
> 3. [Third priority]
