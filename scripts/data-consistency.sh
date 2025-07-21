#!/bin/bash

# Redis Data Consistency Checker
# =============================
# This script checks data consistency between two Redis instances
# (source and target) across all databases.
#
# Usage:
#   ./data-consistency.sh
#   SOURCE_HOST=host1 SOURCE_PORT=6379 TARGET_HOST=host2 ./data-consistency.sh
#
# Environment Variables:
#   SOURCE_HOST     - Source Redis host (default: localhost)
#   SOURCE_PORT     - Source Redis port (default: 6379)
#   SOURCE_USER     - Source Redis username (optional)
#   SOURCE_PASS     - Source Redis password (optional)
#   TARGET_HOST     - Target Redis host (default: localhost)
#   TARGET_PORT     - Target Redis port (default: 6380)
#   TARGET_USER     - Target Redis username (optional)
#   TARGET_PASS     - Target Redis password (optional)
#   USE_SSL         - Enable SSL connections (default: false)
#   SKIP_CERT_VERIFY - Skip SSL certificate verification (default: false)

set -e

# Safe environment variable loading
load_env_file() {
    local env_file="$1"
    if [[ -f "$env_file" ]]; then
        echo "INFO: Auto-loading configuration from .env file..."
        while IFS= read -r line; do
            # Skip comments and empty lines
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$line" ]] && continue

            # Extract variable name and value
            if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
                local var_name="${BASH_REMATCH[1]}"
                local var_value="${BASH_REMATCH[2]}"
                # Remove quotes if present
                var_value="${var_value%\"}"
                var_value="${var_value#\"}"
                var_value="${var_value%\'}"
                var_value="${var_value#\'}"
                export "$var_name"="$var_value"
            fi
        done < "$env_file"
    fi
}

# Check dependencies
check_dependencies() {
    echo "INFO: Checking dependencies..."

    # Check if redis-cli is available
    if ! command -v redis-cli &> /dev/null; then
        echo "ERROR: redis-cli is not installed or not available in PATH"
        echo ""
        echo "Installation instructions:"
        echo "  Ubuntu/Debian: sudo apt-get install redis-tools"
        echo "  CentOS/RHEL:  sudo yum install redis"
        echo "  macOS:        brew install redis"
        echo "  Windows:      Download from https://redis.io/download"
        echo ""
        echo "After installation, ensure redis-cli is available in your PATH"
        exit 1
    fi

    # Check redis-cli version
    REDIS_VERSION=$(redis-cli --version 2>/dev/null | head -1 || echo "unknown")
    echo "INFO: Found redis-cli: $REDIS_VERSION"
    echo ""
}

# Validate numeric input
validate_numeric() {
    local value="$1"
    local name="$2"
    local min="$3"
    local max="$4"

        if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        echo "ERROR: $name must be a number"
        exit 1
    fi

    if [[ "$value" -lt "$min" ]] || [[ "$value" -gt "$max" ]]; then
        echo "ERROR: $name must be between $min and $max"
        exit 1
    fi
}

# Test Redis connection
test_connection() {
    local connection_string="$1"
    local db="$2"
    local label="$3"

    local test_cmd=$(build_redis_cmd "$connection_string" "$db" "ping")
    if ! eval "$test_cmd" &>/dev/null; then
        echo "ERROR: Cannot connect to $label Redis instance"
        echo "  Connection string: $connection_string"
        echo "  Database: $db"
        return 1
    fi
    return 0
}

# Auto-load .env file if it exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
load_env_file "$ENV_FILE"

# Default configuration
SOURCE_HOST=${SOURCE_HOST:-"localhost"}
SOURCE_PORT=${SOURCE_PORT:-"6379"}
SOURCE_USER=${SOURCE_USER:-""}
SOURCE_PASS=${SOURCE_PASS:-""}

TARGET_HOST=${TARGET_HOST:-"localhost"}
TARGET_PORT=${TARGET_PORT:-"6380"}
TARGET_USER=${TARGET_USER:-""}
TARGET_PASS=${TARGET_PASS:-""}

USE_SSL=${USE_SSL:-"false"}
SKIP_CERT_VERIFY=${SKIP_CERT_VERIFY:-"false"}

# Database range configuration
START_DB=${START_DB:-"0"}
END_DB=${END_DB:-"15"}

# Sample size for type checking
SAMPLE_SIZE=${SAMPLE_SIZE:-"10"}

# Show additional keyspace information
SHOW_KEYSPACE=${SHOW_KEYSPACE:-"true"}

# Help function
show_help() {
    cat << EOF
Redis Data Consistency Checker
=============================

This script checks data consistency between two Redis instances (source and target)
across all databases.

Usage:
  ./data-consistency.sh [OPTIONS]

Options:
  -h, --help          Show this help message
  -s, --source HOST   Source Redis host (default: localhost)
  -p, --source-port PORT Source Redis port (default: 6379)
  -t, --target HOST   Target Redis host (default: localhost)
  -P, --target-port PORT Target Redis port (default: 6380)
  -u, --user USER     Redis username (for both source and target)
  -a, --pass PASS     Redis password (for both source and target)
  --ssl               Enable SSL connections
  --insecure          Skip SSL certificate verification
  --start-db NUM      Starting database number (default: 0)
  --end-db NUM        Ending database number (default: 15)
  --sample-size NUM   Number of keys to sample for type checking (default: 10)
  --no-keyspace       Disable additional keyspace information (expires, TTL)

Environment Variables:
  SOURCE_HOST         Source Redis host
  SOURCE_PORT         Source Redis port
  SOURCE_USER         Source Redis username
  SOURCE_PASS         Source Redis password
  TARGET_HOST         Target Redis host
  TARGET_PORT         Target Redis port
  TARGET_USER         Target Redis username
  TARGET_PASS         Target Redis password
  USE_SSL             Enable SSL connections (true/false)
  SKIP_CERT_VERIFY    Skip SSL certificate verification (true/false)
  START_DB            Starting database number (default: 0)
  END_DB              Ending database number (default: 15)
  SAMPLE_SIZE         Number of keys to sample for type checking (default: 10)
  SHOW_KEYSPACE       Show additional keyspace information (true/false, default: true)

Examples:
  # Basic usage with defaults
  ./data-consistency.sh

  # With custom hosts
  ./data-consistency.sh -s redis1.example.com -t redis2.example.com

  # With SSL and authentication
  ./data-consistency.sh --ssl --insecure -u admin -a mypassword

  # Check specific database range
  ./data-consistency.sh --start-db 0 --end-db 5

  # Using environment variables
  SOURCE_HOST=redis1 TARGET_HOST=redis2 USE_SSL=true ./data-consistency.sh

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -s|--source)
            SOURCE_HOST="$2"
            shift 2
            ;;
        -p|--source-port)
            SOURCE_PORT="$2"
            shift 2
            ;;
        -t|--target)
            TARGET_HOST="$2"
            shift 2
            ;;
        -P|--target-port)
            TARGET_PORT="$2"
            shift 2
            ;;
        -u|--user)
            SOURCE_USER="$2"
            TARGET_USER="$2"
            shift 2
            ;;
        -a|--pass)
            SOURCE_PASS="$2"
            TARGET_PASS="$2"
            shift 2
            ;;
        --ssl)
            USE_SSL="true"
            shift
            ;;
        --insecure)
            SKIP_CERT_VERIFY="true"
            shift
            ;;
        --start-db)
            START_DB="$2"
            shift 2
            ;;
        --end-db)
            END_DB="$2"
            shift 2
            ;;
        --sample-size)
            SAMPLE_SIZE="$2"
            shift 2
            ;;
        --no-keyspace)
            SHOW_KEYSPACE="false"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate numeric parameters
validate_numeric "$START_DB" "START_DB" 0 15
validate_numeric "$END_DB" "END_DB" 0 15
validate_numeric "$SAMPLE_SIZE" "SAMPLE_SIZE" 1 100

if [[ "$START_DB" -gt "$END_DB" ]]; then
    echo "ERROR: START_DB ($START_DB) cannot be greater than END_DB ($END_DB)"
    exit 1
fi

# Check dependencies before proceeding
check_dependencies

# Build connection strings
build_connection_string() {
    local host=$1
    local port=$2
    local user=$3
    local pass=$4

    local protocol="redis"
    if [[ "$USE_SSL" == "true" ]]; then
        protocol="rediss"
    fi

    local auth=""
    if [[ -n "$user" && -n "$pass" ]]; then
        auth="$user:$pass@"
    elif [[ -n "$pass" ]]; then
        auth=":$pass@"
    fi

    echo "${protocol}://${auth}${host}:${port}"
}

# Build redis-cli command with options
build_redis_cmd() {
    local connection_string=$1
    local db=$2
    local command=$3

    local cmd="redis-cli"

    if [[ "$USE_SSL" == "true" ]]; then
        cmd="$cmd --tls"
        if [[ "$SKIP_CERT_VERIFY" == "true" ]]; then
            cmd="$cmd --insecure"
        fi
    fi

    cmd="$cmd -u \"$connection_string/$db\" --raw $command"
    echo "$cmd"
}

echo "Redis Data Consistency Checker"
echo "=============================="
echo "Source: $SOURCE_HOST:$SOURCE_PORT"
echo "Target: $TARGET_HOST:$TARGET_PORT"
echo "Database range: $START_DB to $END_DB"
    echo "Sample size: $SAMPLE_SIZE keys"
    if [[ "$SHOW_KEYSPACE" == "false" ]]; then
        echo "Keyspace info: Disabled"
    fi
if [[ "$USE_SSL" == "true" ]]; then
    echo "SSL: Enabled"
    if [[ "$SKIP_CERT_VERIFY" == "true" ]]; then
        echo "Certificate verification: Disabled"
    fi
fi
echo

# Build connection strings
SOURCE_CONN=$(build_connection_string "$SOURCE_HOST" "$SOURCE_PORT" "$SOURCE_USER" "$SOURCE_PASS")
TARGET_CONN=$(build_connection_string "$TARGET_HOST" "$TARGET_PORT" "$TARGET_USER" "$TARGET_PASS")

# Test connections before proceeding
echo "INFO: Testing connections..."
if ! test_connection "$SOURCE_CONN" "0" "source"; then
    exit 1
fi
if ! test_connection "$TARGET_CONN" "0" "target"; then
    exit 1
fi
echo "INFO: Connections successful"
echo

# Function to get keyspace info for a database
get_keyspace_info() {
    local connection_string=$1
    local db=$2

    local info_cmd=$(build_redis_cmd "$connection_string" "$db" "info keyspace")
    local keyspace_info=$(eval $info_cmd 2>/dev/null)

    # Extract database info from keyspace output
    local db_info=$(echo "$keyspace_info" | grep "^db$db:")
    if [[ -n "$db_info" ]]; then
        # Parse: db0:keys=206,expires=102,avg_ttl=1218089
        # Remove the db prefix and split by comma
        local clean_info=$(echo "$db_info" | sed 's/^db[0-9]*://')
        local keys=$(echo "$clean_info" | cut -d',' -f1 | cut -d'=' -f2)
        local expires=$(echo "$clean_info" | cut -d',' -f2 | cut -d'=' -f2)
        local avg_ttl=$(echo "$clean_info" | cut -d',' -f3 | cut -d'=' -f2)
        echo "$keys:$expires:$avg_ttl"
    else
        echo "0:0:0"
    fi
}

# Function to check consistency for a specific database
check_database() {
    local db=$1
    echo
    echo "Database $db:"
    echo "-------------"

        # Key counts (using dbsize for reliability)
    local source_cmd=$(build_redis_cmd "$SOURCE_CONN" "$db" "dbsize")
    local target_cmd=$(build_redis_cmd "$TARGET_CONN" "$db" "dbsize")

    local source_keys=$(eval $source_cmd 2>/dev/null || echo "0")
    local target_keys=$(eval $target_cmd 2>/dev/null || echo "0")

    echo "Source keys: $source_keys"
    echo "Target keys: $target_keys"

    # Skip if both databases are empty
    if [[ "$source_keys" == "0" && "$target_keys" == "0" ]]; then
        echo "INFO: Both databases empty - skipping detailed analysis"
        # Set global variables for summary
        DB_SOURCE_KEYS=0
        DB_TARGET_KEYS=0
        return
    fi

    # Calculate key difference
    if [[ "$source_keys" -gt 0 ]]; then
        local key_diff=$((source_keys - target_keys))
        local key_diff_percent=$((key_diff * 100 / source_keys))
        echo "Key difference: $key_diff ($key_diff_percent%)"
    fi



    # Quick type distribution check (sample of keys)
    if [[ "$source_keys" -gt 0 ]]; then
        local keys_cmd=$(build_redis_cmd "$SOURCE_CONN" "$db" "keys '*'")
        local source_sample=$(eval $keys_cmd 2>/dev/null | head -"$SAMPLE_SIZE")

        if [[ -n "$source_sample" ]]; then
            local source_types=""
            local target_types=""

            while read -r key; do
                [[ -z "$key" ]] && continue

                local type_cmd_source=$(build_redis_cmd "$SOURCE_CONN" "$db" "type \"$key\"")
                local type_cmd_target=$(build_redis_cmd "$TARGET_CONN" "$db" "type \"$key\"")

                local source_type=$(eval $type_cmd_source 2>/dev/null)
                local target_type=$(eval $type_cmd_target 2>/dev/null)

                source_types="$source_types $source_type"
                target_types="$target_types $target_type"
            done <<< "$source_sample"

            # Count types (simplified to avoid line break issues)
            local source_string_count=$(echo "$source_types" | grep -o "string" | wc -l | tr -d ' ')
            local source_hash_count=$(echo "$source_types" | grep -o "hash" | wc -l | tr -d ' ')
            local source_list_count=$(echo "$source_types" | grep -o "list" | wc -l | tr -d ' ')
            local source_set_count=$(echo "$source_types" | grep -o "set" | wc -l | tr -d ' ')
            local source_zset_count=$(echo "$source_types" | grep -o "zset" | wc -l | tr -d ' ')

            local target_string_count=$(echo "$target_types" | grep -o "string" | wc -l | tr -d ' ')
            local target_hash_count=$(echo "$target_types" | grep -o "hash" | wc -l | tr -d ' ')
            local target_list_count=$(echo "$target_types" | grep -o "list" | wc -l | tr -d ' ')
            local target_set_count=$(echo "$target_types" | grep -o "set" | wc -l | tr -d ' ')
            local target_zset_count=$(echo "$target_types" | grep -o "zset" | wc -l | tr -d ' ')

            echo "Sample types ($SAMPLE_SIZE keys):"
            echo "  Source:  String=$source_string_count, Hash=$source_hash_count, List=$source_list_count, Set=$source_set_count, ZSet=$source_zset_count"
            echo "  Target:  String=$target_string_count, Hash=$target_hash_count, List=$target_list_count, Set=$target_set_count, ZSet=$target_zset_count"
        fi
    fi

    # Consistency assessment
    if [[ "$source_keys" != "$target_keys" ]]; then
        if [[ "$source_keys" -gt 0 ]]; then
            local diff_percent=$(( (source_keys - target_keys) * 100 / source_keys ))
            if [[ $diff_percent -gt 5 ]]; then
                echo "ERROR: Key count mismatch: $diff_percent% difference"
            else
                echo "WARNING: Minor key count difference: $diff_percent%"
            fi
        fi
    else
        echo "PASS: Key counts match"
    fi

    # Set global variables for summary
    DB_SOURCE_KEYS=$source_keys
    DB_TARGET_KEYS=$target_keys
}

# Function to show additional keyspace information
show_keyspace_info() {
    local db=$1

    # Only show for databases with data
    if [[ "$DB_SOURCE_KEYS" -gt 0 ]]; then
        echo "Additional keyspace info:"

        # Get keyspace info for source
        local source_keyspace=$(get_keyspace_info "$SOURCE_CONN" "$db")
        local source_expires=$(echo "$source_keyspace" | cut -d: -f2)
        local source_avg_ttl=$(echo "$source_keyspace" | cut -d: -f3)

        # Get keyspace info for target
        local target_keyspace=$(get_keyspace_info "$TARGET_CONN" "$db")
        local target_expires=$(echo "$target_keyspace" | cut -d: -f2)
        local target_avg_ttl=$(echo "$target_keyspace" | cut -d: -f3)

        echo "  Source expires: $source_expires, avg_ttl: $source_avg_ttl"
        echo "  Target expires: $target_expires, avg_ttl: $target_avg_ttl"

        # Check expires consistency
        if [[ "$source_expires" != "$target_expires" ]]; then
            if [[ "$source_expires" -gt 0 ]]; then
                local expire_diff=$((source_expires - target_expires))
                local expire_diff_percent=$((expire_diff * 100 / source_expires))
                echo "  WARNING: Expires difference: $expire_diff ($expire_diff_percent%)"
            fi
        fi
    fi
}

# Check databases in specified range
TOTAL_SOURCE_KEYS=0
TOTAL_TARGET_KEYS=0
DATABASES_WITH_DATA=0

for db in $(seq $START_DB $END_DB); do
    check_database $db

    # Show additional keyspace info (enabled by default)
    if [[ "$SHOW_KEYSPACE" != "false" ]]; then
        show_keyspace_info $db
    fi

    # Use global variables set by check_database function
    TOTAL_SOURCE_KEYS=$((TOTAL_SOURCE_KEYS + DB_SOURCE_KEYS))
    TOTAL_TARGET_KEYS=$((TOTAL_TARGET_KEYS + DB_TARGET_KEYS))

    if [[ "$DB_SOURCE_KEYS" -gt 0 || "$DB_TARGET_KEYS" -gt 0 ]]; then
        DATABASES_WITH_DATA=$((DATABASES_WITH_DATA + 1))
    fi
done

echo
echo "OVERALL SUMMARY"
echo "==============="
echo "Total source keys across all DBs: $TOTAL_SOURCE_KEYS"
echo "Total target keys across all DBs: $TOTAL_TARGET_KEYS"
echo "Databases with data: $DATABASES_WITH_DATA"

if [[ $TOTAL_SOURCE_KEYS -gt 0 ]]; then
    TOTAL_DIFF=$((TOTAL_SOURCE_KEYS - TOTAL_TARGET_KEYS))
    TOTAL_DIFF_PERCENT=$((TOTAL_DIFF * 100 / TOTAL_SOURCE_KEYS))
    echo "Overall key difference: $TOTAL_DIFF ($TOTAL_DIFF_PERCENT%)"

    if [[ $TOTAL_DIFF_PERCENT -eq 0 ]]; then
        echo "RESULT: Perfect consistency across all databases"
    elif [[ $TOTAL_DIFF_PERCENT -le 5 ]]; then
        echo "RESULT: Good overall consistency with minor differences"
    elif [[ $TOTAL_DIFF_PERCENT -le 10 ]]; then
        echo "RESULT: Moderate consistency issues detected"
    else
        echo "RESULT: Significant consistency issues across databases"
    fi
fi
