#!/bin/bash

set -e

echo "Running all checks and tests..."

echo "1. Installing dependencies..."
./scripts/install.sh

echo "2. Running static analysis..."
./scripts/analyze.sh

echo "3. Applying fixes..."
./scripts/fix.sh

echo "4. Formatting code..."
./scripts/format.sh

echo "5. Running all tests..."
./scripts/test-all.sh

echo "All checks and tests completed successfully!"