#!/bin/bash

# Test script for Chainguard PostgreSQL image
set -e

echo "=== Testing Chainguard PostgreSQL Image ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "success")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "error")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "warning")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "info")
            echo -e "${YELLOW}ℹ️  $message${NC}"
            ;;
    esac
}

# Container name
CONTAINER_NAME="test-postgres-chainguard"
IMAGE_NAME="chainguard/postgres:latest"

# Cleanup function
cleanup() {
    print_status "info" "Cleaning up..."
    container stop "$CONTAINER_NAME" 2>/dev/null || true
    container delete "$CONTAINER_NAME" 2>/dev/null || true
}

# Set up trap to cleanup on exit
trap cleanup EXIT

echo ""
print_status "info" "1. Using existing Chainguard PostgreSQL image..."
if container images list | grep -q "chainguard/postgres"; then
    print_status "success" "Found existing Chainguard PostgreSQL image"
else
    print_status "error" "Chainguard PostgreSQL image not found"
    exit 1
fi

echo ""
print_status "info" "2. Starting PostgreSQL container..."
if container run --name "$CONTAINER_NAME" --detach \
    --env POSTGRES_PASSWORD=testpassword \
    --env POSTGRES_USER=testuser \
    --env POSTGRES_DB=testdb \
    "$IMAGE_NAME"; then
    print_status "success" "Successfully started PostgreSQL container"
else
    print_status "error" "Failed to start container"
    exit 1
fi

echo ""
print_status "info" "3. Waiting for PostgreSQL to be ready..."
max_attempts=30
for attempt in $(seq 1 $max_attempts); do
    if container exec "$CONTAINER_NAME" pg_isready -U testuser -d testdb >/dev/null 2>&1; then
        print_status "success" "PostgreSQL is ready!"
        break
    else
        echo -n "⏳ Waiting for PostgreSQL... (attempt $attempt/$max_attempts)"
        if [ $attempt -eq $max_attempts ]; then
            echo ""
            print_status "error" "PostgreSQL failed to start within expected time"
            exit 1
        fi
        sleep 2
    fi
done

echo ""
print_status "info" "4. Testing database connectivity..."
if container exec "$CONTAINER_NAME" psql -U testuser -d testdb -c "SELECT version();" >/dev/null 2>&1; then
    print_status "success" "Database connectivity test successful!"
    echo "PostgreSQL version:"
    container exec "$CONTAINER_NAME" psql -U testuser -d testdb -c "SELECT version();"
else
    print_status "error" "Database connectivity test failed"
    exit 1
fi

echo ""
print_status "info" "5. Testing basic database operations..."

# Create a test table
if container exec "$CONTAINER_NAME" psql -U testuser -d testdb -c "CREATE TABLE test_table (id SERIAL PRIMARY KEY, name VARCHAR(50), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);" >/dev/null 2>&1; then
    print_status "success" "Created test table"
else
    print_status "error" "Failed to create table"
    exit 1
fi

# Insert data
if container exec "$CONTAINER_NAME" psql -U testuser -d testdb -c "INSERT INTO test_table (name) VALUES ('test_record');" >/dev/null 2>&1; then
    print_status "success" "Inserted test data"
else
    print_status "error" "Failed to insert data"
    exit 1
fi

# Query data
if container exec "$CONTAINER_NAME" psql -U testuser -d testdb -c "SELECT * FROM test_table;" >/dev/null 2>&1; then
    print_status "success" "Query test successful!"
    echo "Query result:"
    container exec "$CONTAINER_NAME" psql -U testuser -d testdb -c "SELECT * FROM test_table;"
else
    print_status "error" "Query test failed"
    exit 1
fi

echo ""
print_status "info" "6. Container information:"
container inspect "$CONTAINER_NAME" | jq -r '.[0] | "Container ID: \(.configuration.id)\nStatus: \(.status)\nArchitecture: \(.configuration.architecture)\nIP Address: \(.networks[0].address // "N/A")"'

echo ""
print_status "success" "=== Test completed successfully! ==="
print_status "info" "Container will be automatically cleaned up" 