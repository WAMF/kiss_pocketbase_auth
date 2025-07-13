#!/bin/bash

set -e

echo "Starting PocketBase container..."
docker-compose -f docker-compose.test.yml up -d

echo "Waiting for PocketBase to be ready..."
max_attempts=60
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl -s http://localhost:8090/api/health > /dev/null 2>&1; then
        echo "PocketBase is ready!"
        exit 0
    fi
    
    if [ $((attempt % 10)) -eq 0 ]; then
        echo "Attempt $attempt/$max_attempts: Still waiting for PocketBase (this may take a while on first run)..."
    fi
    sleep 2
    ((attempt++))
done

echo "Error: PocketBase failed to start after $max_attempts attempts"
exit 1