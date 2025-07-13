#!/bin/bash

set -e

echo "Formatting code..."
dart format lib/ test/

echo "Code formatting completed."