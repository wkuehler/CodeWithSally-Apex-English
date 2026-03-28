#!/bin/bash

echo "Attempting to deploy all custom objects..."

# Try to deploy all objects at once
sf project deploy start --source-dir force-app/main/default/objects/ --dry-run

echo "Deployment dry-run completed."

# If you want to actually deploy, uncomment the next line:
# sf project deploy start --source-dir force-app/main/default/objects/
