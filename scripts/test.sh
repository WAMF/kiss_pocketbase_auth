#!/bin/bash

set -e

# Run unit tests only (excluding integration tests)
echo "Running unit tests..."
dart test test/ --exclude-tags=integration

echo "Unit tests completed."