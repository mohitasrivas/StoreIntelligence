import os
from dotenv import load_dotenv

load_dotenv()

# Azure AI Foundry
PROJECT_ENDPOINT = os.environ["PROJECT_ENDPOINT"]
MODEL_DEPLOYMENT_NAME = os.getenv("MODEL_DEPLOYMENT_NAME", "gpt-4o")

# Fabric Data Agent endpoints (from published Fabric agents)
FABRIC_SALES_AGENT_ENDPOINT = os.environ["FABRIC_SALES_AGENT_ENDPOINT"]
FABRIC_INVENTORY_AGENT_ENDPOINT = os.environ["FABRIC_INVENTORY_AGENT_ENDPOINT"]
FABRIC_LABOR_AGENT_ENDPOINT = os.environ["FABRIC_LABOR_AGENT_ENDPOINT"]

# Fabric auth (Service Principal)
FABRIC_TENANT_ID = os.environ["FABRIC_TENANT_ID"]
FABRIC_CLIENT_ID = os.environ["FABRIC_CLIENT_ID"]
FABRIC_CLIENT_SECRET = os.environ["FABRIC_CLIENT_SECRET"]
