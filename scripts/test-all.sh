#!/bin/bash

set -e

echo "Starting PocketBase and running all tests..."

# Check if PocketBase is already running
if curl -s http://localhost:8090/api/health > /dev/null 2>&1; then
    echo "PocketBase is already running and healthy!"
    STARTED_CONTAINER=false
else
    echo "Starting PocketBase container..."
    ./scripts/docker-up.sh
    STARTED_CONTAINER=true
fi

# Ensure cleanup happens even if tests fail (only if we started it)
cleanup() {
    if [ "$STARTED_CONTAINER" = true ]; then
        echo "Cleaning up..."
        ./scripts/docker-down.sh
    else
        echo "Leaving existing PocketBase container running..."
    fi
}
trap cleanup EXIT

# Run all tests
echo "Running all tests..."
dart test

echo "All tests completed successfully."