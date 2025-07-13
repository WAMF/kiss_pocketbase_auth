#!/bin/bash

set -e

echo "Stopping PocketBase container..."
docker-compose -f docker-compose.test.yml down

echo "PocketBase container stopped."