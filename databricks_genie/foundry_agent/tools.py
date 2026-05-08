"""Tool functions that call Databricks Genie Spaces via the Conversation API."""

import time
import json
import requests

from config import (
    DATABRICKS_HOST,
    DATABRICKS_TOKEN,
    GENIE_SALES_SPACE_ID,
    GENIE_INVENTORY_SPACE_ID,
    GENIE_LABOR_SPACE_ID,
)

_BASE_URL = f"{DATABRICKS_HOST.rstrip('/')}/api/2.0/genie/spaces"
_HEADERS = {
    "Authorization": f"Bearer {DATABRICKS_TOKEN}",
    "Content-Type": "application/json",
}

# Polling config
_POLL_INITIAL_INTERVAL = 1.0   # seconds
_POLL_MAX_INTERVAL = 60.0      # seconds
_POLL_TIMEOUT = 300.0           # 5 minutes
_POLL_BACKOFF_FACTOR = 2.0


def _call_genie_space(space_id: str, question: str) -> str:
    """Send a question to a Genie Space and poll for the completed response."""

    # 1. Start a new conversation
    start_url = f"{_BASE_URL}/{space_id}/start-conversation"
    resp = requests.post(
        start_url, headers=_HEADERS, json={"content": question}, timeout=30
    )
    resp.raise_for_status()
    data = resp.json()

    conversation_id = data["conversation"]["id"]
    message_id = data["message"]["id"]

    # 2. Poll for completion
    msg_url = (
        f"{_BASE_URL}/{space_id}/conversations/{conversation_id}"
        f"/messages/{message_id}"
    )

    interval = _POLL_INITIAL_INTERVAL
    elapsed = 0.0

    while elapsed < _POLL_TIMEOUT:
        time.sleep(interval)
        elapsed += interval

        poll_resp = requests.get(msg_url, headers=_HEADERS, timeout=30)
        poll_resp.raise_for_status()
        msg = poll_resp.json()

        status = msg.get("status", "")

        if status == "COMPLETED":
            return _extract_response(msg, space_id, conversation_id, message_id)

        if status in ("FAILED", "CANCELLED"):
            error = msg.get("error") or status
            return f"Genie query failed: {error}"

        # Exponential backoff
        interval = min(interval * _POLL_BACKOFF_FACTOR, _POLL_MAX_INTERVAL)

    return "Genie query timed out after 5 minutes."


def _extract_response(
    msg: dict, space_id: str, conversation_id: str, message_id: str
) -> str:
    """Extract text and query results from a completed Genie message."""
    parts = []

    attachments = msg.get("attachments") or []
    for att in attachments:
        # Text response
        if att.get("text"):
            text = att["text"]
            if isinstance(text, list):
                parts.append("".join(text))
            else:
                parts.append(str(text))

        # SQL query
        if att.get("query", {}).get("query"):
            parts.append(f"\nGenerated SQL:\n```sql\n{att['query']['query']}\n```")

        # Fetch tabular results if attachment_id is present
        attachment_id = att.get("attachment_id")
        if attachment_id:
            try:
                result_url = (
                    f"{_BASE_URL}/{space_id}/conversations/{conversation_id}"
                    f"/messages/{message_id}/query-result/{attachment_id}"
                )
                result_resp = requests.get(
                    result_url, headers=_HEADERS, timeout=30
                )
                result_resp.raise_for_status()
                result_data = result_resp.json()
                if result_data:
                    parts.append(f"\nQuery results:\n{json.dumps(result_data, indent=2)}")
            except requests.RequestException:
                pass  # results are optional; text response is sufficient

    return "\n".join(parts) if parts else "(No response from Genie)"


def query_sales_genie(question: str) -> str:
    """Query the Databricks Genie Sales Space.

    Use for questions about revenue, orders, margins, product/category/store
    sales performance, trends, and comparisons.

    Args:
        question: The sales-related question to answer.

    Returns:
        The Genie Space response with sales data and analysis.
    """
    return _call_genie_space(GENIE_SALES_SPACE_ID, question)


def query_inventory_genie(question: str) -> str:
    """Query the Databricks Genie Inventory & OOS Space.

    Use for questions about stock levels, out-of-stock classification
    (chronic, true, phantom, at-risk), reorder points, warehouse inventory,
    demand signals, and supply-chain risk.

    Args:
        question: The inventory-related question to answer.

    Returns:
        The Genie Space response with inventory data and analysis.
    """
    return _call_genie_space(GENIE_INVENTORY_SPACE_ID, question)


def query_labor_genie(question: str) -> str:
    """Query the Databricks Genie Labor Space.

    Use for questions about staffing, associate assignments, shift coverage,
    roles, tasks completed, orders managed, and labor efficiency.

    Args:
        question: The labor-related question to answer.

    Returns:
        The Genie Space response with labor data and analysis.
    """
    return _call_genie_space(GENIE_LABOR_SPACE_ID, question)
