#!/bin/bash

set -e

echo "Cleaning up Docker containers and volumes..."
docker-compose -f docker-compose.test.yml down -v
docker system prune -f

echo "Cleanup completed."