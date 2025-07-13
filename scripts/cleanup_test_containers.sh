#!/bin/bash

echo "Cleaning up test containers..."

# Stop and remove any running pocketbase_test containers
docker stop pocketbase_test 2>/dev/null || true
docker rm pocketbase_test 2>/dev/null || true

# Clean up using docker-compose
docker-compose -f docker-compose.test.yml down --remove-orphans --volumes 2>/dev/null || true

echo "Cleanup complete."