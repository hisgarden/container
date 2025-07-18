#!/usr/bin/env python3

import sys
import time
import subprocess
import json

def run_command(cmd, check=True):
    """Run a command and return the result"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=check)
        return result.stdout.strip(), result.stderr.strip(), result.returncode
    except subprocess.CalledProcessError as e:
        return e.stdout.strip(), e.stderr.strip(), e.returncode

def test_postgres_chainguard():
    """Test the Chainguard PostgreSQL image"""
    print("=== Testing Chainguard PostgreSQL Image ===")
    
    # Step 1: Check for existing Chainguard PostgreSQL image
    print("\n1. Checking for existing Chainguard PostgreSQL image...")
    stdout, stderr, code = run_command("container images list | grep chainguard/postgres")
    if code == 0:
        print("✅ Found existing Chainguard PostgreSQL image")
    else:
        print("❌ Chainguard PostgreSQL image not found")
        return False
    
    # Step 2: Start the PostgreSQL container
    print("\n2. Starting PostgreSQL container...")
    container_name = "test-postgres-chainguard"
    
    # Stop and remove any existing container with the same name
    run_command(f"container stop {container_name}", check=False)
    run_command(f"container delete {container_name}", check=False)
    
    # Start the PostgreSQL container
    start_cmd = f"""container run --name {container_name} --detach \
        --env POSTGRES_PASSWORD=testpassword \
        --env POSTGRES_USER=testuser \
        --env POSTGRES_DB=testdb \
        chainguard/postgres:latest"""
    
    stdout, stderr, code = run_command(start_cmd)
    if code == 0:
        print("✅ Successfully started PostgreSQL container")
        print(f"Container ID: {stdout}")
    else:
        print(f"❌ Failed to start container: {stderr}")
        return False
    
    # Step 3: Wait for PostgreSQL to be ready
    print("\n3. Waiting for PostgreSQL to be ready...")
    max_attempts = 30
    for attempt in range(max_attempts):
        stdout, stderr, code = run_command(f"container exec {container_name} pg_isready -U testuser -d testdb")
        if code == 0:
            print("✅ PostgreSQL is ready!")
            break
        else:
            print(f"⏳ Waiting for PostgreSQL... (attempt {attempt + 1}/{max_attempts})")
            time.sleep(2)
    else:
        print("❌ PostgreSQL failed to start within expected time")
        return False
    
    # Step 4: Test database connectivity
    print("\n4. Testing database connectivity...")
    test_query = "SELECT version();"
    exec_cmd = f"""container exec {container_name} psql -U testuser -d testdb -c "{test_query}" """
    
    stdout, stderr, code = run_command(exec_cmd)
    if code == 0:
        print("✅ Database connectivity test successful!")
        print(f"PostgreSQL version: {stdout.strip()}")
    else:
        print(f"❌ Database connectivity test failed: {stderr}")
        return False
    
    # Step 5: Test basic database operations
    print("\n5. Testing basic database operations...")
    
    # Create a test table
    create_table = "CREATE TABLE test_table (id SERIAL PRIMARY KEY, name VARCHAR(50), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
    stdout, stderr, code = run_command(f"""container exec {container_name} psql -U testuser -d testdb -c "{create_table}" """)
    if code == 0:
        print("✅ Created test table")
    else:
        print(f"❌ Failed to create table: {stderr}")
        return False
    
    # Insert data
    insert_data = "INSERT INTO test_table (name) VALUES ('test_record');"
    stdout, stderr, code = run_command(f"""container exec {container_name} psql -U testuser -d testdb -c "{insert_data}" """)
    if code == 0:
        print("✅ Inserted test data")
    else:
        print(f"❌ Failed to insert data: {stderr}")
        return False
    
    # Query data
    select_data = "SELECT * FROM test_table;"
    stdout, stderr, code = run_command(f"""container exec {container_name} psql -U testuser -d testdb -c "{select_data}" """)
    if code == 0:
        print("✅ Query test successful!")
        print(f"Query result:\n{stdout}")
    else:
        print(f"❌ Query test failed: {stderr}")
        return False
    
    # Step 6: Get container information
    print("\n6. Container information:")
    stdout, stderr, code = run_command(f"container inspect {container_name}")
    if code == 0:
        try:
            container_info = json.loads(stdout)
            if container_info:
                info = container_info[0]
                print(f"Container ID: {info.get('configuration', {}).get('id', 'N/A')}")
                print(f"Status: {info.get('status', 'N/A')}")
                print(f"Architecture: {info.get('configuration', {}).get('architecture', 'N/A')}")
                if 'networks' in info and info['networks']:
                    print(f"IP Address: {info['networks'][0].get('address', 'N/A')}")
        except json.JSONDecodeError:
            print("Could not parse container information")
    
    # Step 7: Cleanup
    print("\n7. Cleaning up...")
    stdout, stderr, code = run_command(f"container stop {container_name}")
    if code == 0:
        print("✅ Container stopped")
    else:
        print(f"❌ Failed to stop container: {stderr}")
    
    stdout, stderr, code = run_command(f"container delete {container_name}")
    if code == 0:
        print("✅ Container deleted")
    else:
        print(f"❌ Failed to delete container: {stderr}")
    
    print("\n=== Test completed successfully! ===")
    return True

if __name__ == "__main__":
    success = test_postgres_chainguard()
    sys.exit(0 if success else 1) 