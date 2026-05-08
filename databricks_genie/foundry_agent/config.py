import os
from dotenv import load_dotenv

load_dotenv()

# Azure AI Foundry
PROJECT_ENDPOINT = os.environ["PROJECT_ENDPOINT"]
MODEL_DEPLOYMENT_NAME = os.getenv("MODEL_DEPLOYMENT_NAME", "gpt-4o")

# Databricks
DATABRICKS_HOST = os.environ["DATABRICKS_HOST"]  # e.g. https://adb-xxxx.azuredatabricks.net
DATABRICKS_TOKEN = os.environ["DATABRICKS_TOKEN"]  # PAT or OAuth M2M token

# Genie Space IDs
GENIE_SALES_SPACE_ID = os.environ["GENIE_SALES_SPACE_ID"]
GENIE_INVENTORY_SPACE_ID = os.environ["GENIE_INVENTORY_SPACE_ID"]
GENIE_LABOR_SPACE_ID = os.environ["GENIE_LABOR_SPACE_ID"]
