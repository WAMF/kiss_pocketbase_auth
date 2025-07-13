#!/bin/bash

set -e

echo "Running integration tests..."
dart test test/integration/

echo "Integration tests completed."