"""Store Intelligence Foundry Agent — Databricks Genie Edition.

Orchestrates three Databricks Genie Spaces (Sales, Inventory, Labor) to answer
retail store intelligence questions via an Azure AI Foundry hosted agent.
"""

from azure.ai.projects import AIProjectClient
from azure.ai.agents.models import FunctionTool, ToolSet
from azure.identity import DefaultAzureCredential

from config import PROJECT_ENDPOINT, MODEL_DEPLOYMENT_NAME
from tools import query_sales_genie, query_inventory_genie, query_labor_genie

SYSTEM_PROMPT = """You are the **Store Intelligence Assistant**, an AI orchestrator
for retail store operations. You coordinate three specialist Databricks Genie Spaces:

1. **Sales Genie** – revenue, orders, margins, product/category/store performance
2. **Inventory Genie** – stock levels, OOS classification (chronic/true/phantom/at-risk), reorder, demand, supply-chain risk
3. **Labor Genie** – staffing, shifts, roles, tasks completed, orders managed, labor efficiency

## Routing Rules
- Sales questions → query_sales_genie
- Inventory / OOS / stock questions → query_inventory_genie
- Labor / staffing questions → query_labor_genie
- Cross-domain questions (e.g. "store health check") → call ALL relevant Genie Spaces, then synthesize
- Unknown domain → ask the user to clarify

## Response Guidelines
- Always state the time window (e.g. "last 7 days") and store scope
- Use tables for multi-row data
- Highlight risks and anomalies
- When synthesizing cross-domain answers, organize by domain with clear headings
- Be concise and action-oriented
- Genie returns SQL-generated tabular data; present it clearly to the user
"""

_tool_functions = {
    "query_sales_genie": query_sales_genie,
    "query_inventory_genie": query_inventory_genie,
    "query_labor_genie": query_labor_genie,
}


def create_agent():
    """Create the Foundry hosted agent with Genie tool bindings."""
    client = AIProjectClient(
        endpoint=PROJECT_ENDPOINT,
        credential=DefaultAzureCredential(),
    )

    functions = FunctionTool(functions=list(_tool_functions.values()))
    toolset = ToolSet()
    toolset.add(functions)

    agent = client.agents.create_agent(
        model=MODEL_DEPLOYMENT_NAME,
        name="store-intelligence-databricks",
        instructions=SYSTEM_PROMPT,
        toolset=toolset,
    )
    print(f"Agent created: {agent.id}")
    return client, agent


def chat(client: AIProjectClient, agent, user_message: str) -> str:
    """Send a message and return the agent response, handling tool calls."""
    thread = client.agents.threads.create()
    client.agents.messages.create(thread_id=thread.id, role="user", content=user_message)

    run = client.agents.runs.create_and_process(thread_id=thread.id, agent_id=agent.id)

    if run.status == "failed":
        return f"Run failed: {run.last_error}"

    messages = client.agents.messages.list(thread_id=thread.id)
    # Return the last assistant message
    for msg in reversed(list(messages)):
        if msg.role == "assistant" and msg.content:
            return msg.content[0].text.value
    return "(No response)"


def main():
    """Interactive CLI for testing the Store Intelligence agent."""
    print("Initializing Store Intelligence Foundry Agent (Databricks Genie)...")
    client, agent = create_agent()
    print("Ready. Type your question (or 'quit' to exit).\n")

    try:
        while True:
            user_input = input("You: ").strip()
            if not user_input or user_input.lower() in ("quit", "exit", "q"):
                break
            response = chat(client, agent, user_input)
            print(f"\nAssistant: {response}\n")
    finally:
        client.agents.delete_agent(agent.id)
        print("Agent deleted.")


if __name__ == "__main__":
    main()
