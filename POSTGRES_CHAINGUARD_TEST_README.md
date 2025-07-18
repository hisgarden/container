# PostgreSQL Chainguard Image Test Results

## Overview
This document summarizes the testing of the Chainguard PostgreSQL image using Apple's Container tool.

## Test Results

### ✅ Successful Tests
- **Image Availability**: Found existing `chainguard/postgres:latest` image
- **Container Startup**: Successfully started PostgreSQL container
- **Database Connectivity**: PostgreSQL 17.5 ready and accessible
- **Basic Operations**: 
  - Table creation ✅
  - Data insertion ✅
  - Data querying ✅
- **Container Management**: Proper cleanup and resource management

### Technical Details
- **PostgreSQL Version**: 17.5
- **Architecture**: aarch64-unknown-linux-gnu
- **Compiler**: aarch64-unknown-linux-gnu-gcc (Wolfi 15.1.0-r1) 15.1.0
- **Container Network**: 192.168.64.x/24 subnet
- **Container Tool**: Apple Container (not Docker)

## Test Scripts

### Shell Script Version
```bash
./test-postgres-chainguard.sh
```

### Python Script Version
```bash
python3 test-postgres-chainguard.py
```

## Key Differences from Docker

### Command Syntax
| Docker | Apple Container |
|--------|-----------------|
| `docker run --publish 5432:5432` | `container run` (no port publishing needed) |
| `docker exec` | `container exec` |
| `docker stop` | `container stop` |
| `docker rm` | `container delete` |

### Network Access
- Apple Container provides internal networking
- Containers are accessible via their hostname (e.g., `test-postgres-chainguard.test`)
- No need for port publishing for internal container communication

## Environment Variables Used
```bash
POSTGRES_PASSWORD=testpassword
POSTGRES_USER=testuser
POSTGRES_DB=testdb
```

## Database Operations Tested
1. **Version Check**: `SELECT version();`
2. **Table Creation**: 
   ```sql
   CREATE TABLE test_table (
       id SERIAL PRIMARY KEY, 
       name VARCHAR(50), 
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );
   ```
3. **Data Insertion**: `INSERT INTO test_table (name) VALUES ('test_record');`
4. **Data Querying**: `SELECT * FROM test_table;`

## Security Benefits of Chainguard Images
- **Minimal Attack Surface**: Reduced number of packages and dependencies
- **Regular Security Updates**: Automated vulnerability scanning and patching
- **Distroless Base**: No unnecessary system tools or shells
- **SBOM Integration**: Software Bill of Materials for transparency

## Usage Recommendations

### For Development
```bash
# Start a PostgreSQL container for development
container run --name dev-postgres --detach \
    --env POSTGRES_PASSWORD=devpassword \
    --env POSTGRES_USER=devuser \
    --env POSTGRES_DB=devdb \
    chainguard/postgres:latest
```

### For Testing
```bash
# Run the automated test
./test-postgres-chainguard.sh
```

### For Production
- Use specific version tags instead of `latest`
- Implement proper backup strategies
- Configure appropriate resource limits
- Set up monitoring and logging

## Troubleshooting

### Common Issues
1. **Image Not Found**: Ensure the Chainguard image is available locally
2. **Container Won't Start**: Check environment variables and resource availability
3. **Database Connection Issues**: Verify PostgreSQL is ready using `pg_isready`

### Debug Commands
```bash
# Check container status
container list

# View container logs
container logs test-postgres-chainguard

# Inspect container details
container inspect test-postgres-chainguard

# Execute commands in container
container exec test-postgres-chainguard psql -U testuser -d testdb
```

## Conclusion
The Chainguard PostgreSQL image works excellently with Apple's Container tool. It provides a secure, lightweight PostgreSQL instance suitable for development, testing, and production use cases. The image successfully handles all basic database operations and integrates well with the Apple Container ecosystem. 