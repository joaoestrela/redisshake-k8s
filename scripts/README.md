# Redis Scripts

A collection of useful scripts for Redis operations and monitoring.

## Data Consistency Checker

A bash script to check data consistency between two Redis instances across all databases. Useful for replication monitoring, migration validation, backup verification, load balancer testing, and disaster recovery scenarios.

### Quick Start

#### Basic Usage

```bash
# Check consistency between local Redis instances
./data-consistency.sh

# With custom hosts
./data-consistency.sh -s redis1.example.com -t redis2.example.com

# With SSL and authentication
./data-consistency.sh --ssl --insecure -u admin -a mypassword
```

#### Using Environment Variables

```bash
# Set environment variables
export SOURCE_HOST=redis1.example.com
export TARGET_HOST=redis2.example.com
export USE_SSL=true
export SKIP_CERT_VERIFY=true

# Run the script
./data-consistency.sh
```

#### Using Configuration File

```bash
# Copy the example configuration
cp data-consistency.example.env .env

# Edit .env with your Redis details
# Then source and run
source .env && ./data-consistency.sh
```

### Configuration

#### Command Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `-s, --source HOST` | Source Redis host | localhost |
| `-p, --source-port PORT` | Source Redis port | 6379 |
| `-t, --target HOST` | Target Redis host | localhost |
| `-P, --target-port PORT` | Target Redis port | 6380 |
| `-u, --user USER` | Redis username | (none) |
| `-a, --pass PASS` | Redis password | (none) |
| `--ssl` | Enable SSL connections | false |
| `--insecure` | Skip SSL certificate verification | false |
| `--start-db NUM` | Starting database number | 0 |
| `--end-db NUM` | Ending database number | 15 |
| `--sample-size NUM` | Number of keys to sample for type checking | 10 |
| `--no-keyspace` | Disable additional keyspace information (expires, TTL) | false |
| `-h, --help` | Show help message | - |

#### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SOURCE_HOST` | Source Redis host | localhost |
| `SOURCE_PORT` | Source Redis port | 6379 |
| `SOURCE_USER` | Source Redis username | (none) |
| `SOURCE_PASS` | Source Redis password | (none) |
| `TARGET_HOST` | Target Redis host | localhost |
| `TARGET_PORT` | Target Redis port | 6380 |
| `TARGET_USER` | Target Redis username | (none) |
| `TARGET_PASS` | Target Redis password | (none) |
| `USE_SSL` | Enable SSL connections | false |
| `SKIP_CERT_VERIFY` | Skip SSL certificate verification | false |
| `START_DB` | Starting database number | 0 |
| `END_DB` | Ending database number | 15 |
| `SAMPLE_SIZE` | Number of keys to sample for type checking | 10 |
| `SHOW_KEYSPACE` | Show additional keyspace information (true/false, default: true) | true |

### Examples

#### Local Redis Instances

```bash
# Check consistency between local Redis instances on different ports
./data-consistency.sh -s localhost -p 6379 -t localhost -P 6380
```

#### Redis with SSL

```bash
# With SSL and authentication
./data-consistency.sh \
  --ssl --insecure \
  -s redis1.example.com \
  -p 6379 \
  -t redis2.example.com \
  -p 6379 \
  -u admin -a your-password

# Check specific database range with custom sample size
./data-consistency.sh \
  --start-db 0 --end-db 5 \
  --sample-size 20 \
  -s redis1.example.com -t redis2.example.com

# Disable keyspace information
./data-consistency.sh \
  --no-keyspace \
  -s redis1.example.com -t redis2.example.com
```

#### Using Environment Variables

```bash
# Set environment variables
export SOURCE_HOST=redis1.example.com
export TARGET_HOST=redis2.example.com
export SOURCE_PORT=6379
export TARGET_PORT=6379
export USE_SSL=false

./data-consistency.sh
```

### Output

The script provides detailed consistency information including key counts, type distributions, and keyspace metrics:

```
INFO: Auto-loading configuration from .env file...
INFO: Checking dependencies...
INFO: Found redis-cli: redis-cli 7.2.7

Redis Data Consistency Checker
==============================
Source: redis1.example.com:6379
Target: redis2.example.com:6379
Database range: 0 to 15
Sample size: 10 keys
SSL: Enabled
Certificate verification: Disabled

INFO: Testing connections...
INFO: Connections successful

Database 0:
-------------
Source keys: 206
Target keys: 206
Key difference: 0 (0%)
Sample types (10 keys):
  Source:  String=3, Hash=6, List=0, Set=0, ZSet=0
  Target:  String=3, Hash=6, List=0, Set=0, ZSet=0
PASS: Key counts match
Additional keyspace info:
  Source expires: 102, avg_ttl: 1205283
  Target expires: 102, avg_ttl: 1186300

Database 1:
-------------
Source keys: 0
Target keys: 0
INFO: Both databases empty - skipping detailed analysis

Database 3:
-------------
Source keys: 3367
Target keys: 3367
Key difference: 0 (0%)
Sample types (10 keys):
  Source:  String=1, Hash=9, List=0, Set=0, ZSet=0
  Target:  String=1, Hash=9, List=0, Set=0, ZSet=0
PASS: Key counts match
Additional keyspace info:
  Source expires: 778, avg_ttl: 364788655
  Target expires: 778, avg_ttl: 356956185

OVERALL SUMMARY
===============
Total source keys across all DBs: 4116
Total target keys across all DBs: 4116
Databases with data: 6
Overall key difference: 0 (0%)
RESULT: Perfect consistency across all databases
```

### Understanding Results

#### Sync Validation Indicators

When Redis replication or synchronization is working correctly, you should see:

**✅ Good Sync Indicators:**
- **Key counts match**: Source and target have identical key counts
- **Type distributions match**: Similar distribution of String, Hash, List, Set, ZSet types
- **Expires counts match**: Same number of keys with TTL in both instances
- **TTL values similar**: Average TTL values should be close (small differences due to timing are normal)
- **Overall difference ≤ 5%**: Minor differences may indicate ongoing sync

**⚠️ Potential Sync Issues:**
- **Key count mismatches**: Target missing keys from source
- **Type distribution differences**: Data structure inconsistencies
- **Expires count differences**: TTL replication issues
- **Large TTL differences**: Significant timing delays in replication
- **Overall difference > 10%**: Major synchronization problems

#### Keyspace Information

The additional keyspace info shows:
- **Expires**: Number of keys with TTL (should match between source/target)
- **avg_ttl**: Average time-to-live in milliseconds (should be similar)
- **Warnings**: Alerts for significant differences in expiration patterns


