#!/bin/bash

set -e

echo "Running static analysis..."
dart analyze

echo "Static analysis completed."