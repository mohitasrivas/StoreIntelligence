"""Tool functions that call published Fabric Data Agents via REST API."""

import json
import requests
import msal

from config import (
    FABRIC_TENANT_ID,
    FABRIC_CLIENT_ID,
    FABRIC_CLIENT_SECRET,
    FABRIC_SALES_AGENT_ENDPOINT,
    FABRIC_INVENTORY_AGENT_ENDPOINT,
    FABRIC_LABOR_AGENT_ENDPOINT,
)

_AUTHORITY = f"https://login.microsoftonline.com/{FABRIC_TENANT_ID}"
_SCOPES = ["https://api.fabric.microsoft.com/.default"]

_msal_app = msal.ConfidentialClientApplication(
    FABRIC_CLIENT_ID,
    authority=_AUTHORITY,
    client_credential=FABRIC_CLIENT_SECRET,
)


def _get_fabric_token() -> str:
    """Acquire an access token for Fabric API using client credentials."""
    result = _msal_app.acquire_token_for_client(scopes=_SCOPES)
    if "access_token" not in result:
        raise RuntimeError(f"Failed to acquire Fabric token: {result.get('error_description', result)}")
    return result["access_token"]


def _call_fabric_agent(endpoint: str, question: str) -> str:
    """Send a question to a published Fabric Data Agent and return the response."""
    token = _get_fabric_token()
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    payload = {"messages": [{"role": "user", "content": question}]}
    resp = requests.post(endpoint, headers=headers, json=payload, timeout=120)
    resp.raise_for_status()
    data = resp.json()
    # Extract the assistant reply from the response
    if "choices" in data:
        return data["choices"][0]["message"]["content"]
    if "result" in data:
        return data["result"]
    return json.dumps(data)


def query_sales_agent(question: str) -> str:
    """Query the Fabric Sales Data Agent.

    Use for questions about revenue, orders, margins, product/category/store
    sales performance, trends, and comparisons.

    Args:
        question: The sales-related question to answer.

    Returns:
        The agent's response with sales data and analysis.
    """
    return _call_fabric_agent(FABRIC_SALES_AGENT_ENDPOINT, question)


def query_inventory_agent(question: str) -> str:
    """Query the Fabric Inventory Data Agent.

    Use for questions about stock levels, out-of-stock classification
    (chronic, true, phantom, at-risk), reorder points, warehouse inventory,
    demand signals, and supply-chain risk.

    Args:
        question: The inventory-related question to answer.

    Returns:
        The agent's response with inventory data and analysis.
    """
    return _call_fabric_agent(FABRIC_INVENTORY_AGENT_ENDPOINT, question)


def query_labor_agent(question: str) -> str:
    """Query the Fabric Labor Data Agent.

    Use for questions about staffing, associate assignments, shift coverage,
    roles, tasks completed, orders managed, and labor efficiency.

    Args:
        question: The labor-related question to answer.

    Returns:
        The agent's response with labor data and analysis.
    """
    return _call_fabric_agent(FABRIC_LABOR_AGENT_ENDPOINT, question)
