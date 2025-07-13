#!/bin/bash

set -e

echo "Applying automatic fixes..."
dart fix --apply

echo "Automatic fixes applied."