# RedisShake Helm Chart

> Chart version: `0.1.0` &nbsp;|&nbsp; App version: `latest`
> [Chart Source](https://github.com/joaoestrela/redisshake-k8s) &nbsp;|&nbsp; [RedisShake Project](https://github.com/alibaba/RedisShake) &nbsp;|&nbsp; [RedisShake Docs](https://tair-opensource.github.io/RedisShake/)

## Table of Contents
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Values](#values)
- [Usage Examples](#usage-examples)
- [Monitoring & Troubleshooting](#monitoring--troubleshooting)

A Helm chart for deploying RedisShake, a Redis data migration and synchronization tool.

## Introduction

RedisShake is a tool for Redis data migration and synchronization. It supports multiple modes:
- **Sync**: Real-time synchronization from source to target Redis
- **Scan**: Scan and migrate existing data

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Redis instances (source and/or target)

## Installation

```bash
# Add the OCI registry (Might be needed depending on your setup)
helm registry login ghcr.io

# Install the chart
helm install my-redisshake oci://ghcr.io/joaoestrela/redisshake-k8s/helm-charts/redisshake --version 0.1.0
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| advanced.aws_psync | string | `""` | Custom psync command for AWS ElastiCache |
| advanced.dir | string | `"data"` | Data directory |
| advanced.empty_db_before_sync | bool | `false` | Clear target before sync |
| advanced.log_compress | bool | `true` | Compress rotated logs |
| advanced.log_file | string | `"shake.log"` | Log file name |
| advanced.log_interval | int | `5` | Log interval in seconds |
| advanced.log_level | string | `"info"` | Log level (debug, info, warn) |
| advanced.log_max_age | int | `7` | Log retention in days |
| advanced.log_max_backups | int | `3` | Number of log backups |
| advanced.log_max_size | int | `512` | Max log size in MiB |
| advanced.log_rotation | bool | `true` | Enable log rotation |
| advanced.ncpu | int | `0` | Number of CPU cores to use (0 = auto) |
| advanced.pipeline_count_limit | int | `1024` | Pipeline size |
| advanced.pprof.enabled | bool | `false` | Enable PProf debugging |
| advanced.pprof.port | int | `6060` | PProf port when enabled |
| advanced.rdb_restore_command_behavior | string | `"panic"` | RDB restore command behavior (panic, rewrite, skip) |
| advanced.status.enabled | bool | `true` | Enable status monitoring |
| advanced.status.port | int | `8080` | Status port when enabled |
| advanced.target_redis_client_max_querybuf_len | int | `1073741824` | Max query buffer length for target Redis client (bytes) |
| advanced.target_redis_proto_max_bulk_len | int | `512000000` | Max bulk length for target Redis protocol (bytes) |
| affinity | object | `{}` | Pod affinity rules |
| deployment.annotations | object | `{}` | Additional annotations for the deployment |
| deployment.labels | object | `{}` | Additional labels for the deployment |
| deployment.podAnnotations | object | `{}` | Additional pod annotations |
| deployment.podLabels | object | `{}` | Additional pod labels |
| deployment.podSecurityContext | object | `{}` | Pod security context |
| deployment.resources | object | `{"limits":{"cpu":"1000m","memory":"1Gi"},"requests":{"cpu":"100m","memory":"128Mi"}}` | Resource limits and requests |
| deployment.securityContext | object | `{}` | Container security context |
| filter.allow_command | list | `[]` | Allow only specific commands |
| filter.allow_command_group | list | `[]` | Allow only specific command groups |
| filter.allow_db | list | `[]` | Allow only specific database numbers |
| filter.allow_key_prefix | list | `[]` | Allow keys with specific prefixes |
| filter.allow_key_regex | list | `[]` | Allow keys matching regex patterns |
| filter.allow_key_suffix | list | `[]` | Allow keys with specific suffixes |
| filter.allow_keys | list | `[]` | Allow only specific keys |
| filter.block_command | list | `[]` | Block specific commands |
| filter.block_command_group | list | `[]` | Block specific command groups |
| filter.block_db | list | `[]` | Block specific database numbers |
| filter.block_key_prefix | list | `[]` | Block keys with specific prefixes |
| filter.block_key_regex | list | `[]` | Block keys matching regex patterns |
| filter.block_key_suffix | list | `[]` | Block keys with specific suffixes |
| filter.block_keys | list | `[]` | Block specific keys |
| filter.function | string | `""` | Lua function for custom filtering |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"ghcr.io/tair-opensource/redisshake"` | RedisShake image repository |
| image.tag | string | `"latest"` | RedisShake image tag |
| imagePullSecrets | list | `[]` | Kubernetes image pull secrets |
| mode | string | `"sync"` | RedisShake operation mode (sync, scan, restore, dump, decode) |
| module.target_mbbloom_version | int | `20603` | Bloom filter version |
| nodeSelector | object | `{}` | Node selector for pod placement |
| persistence.accessMode | string | `"ReadWriteOnce"` | Access mode for persistent volume |
| persistence.enabled | bool | `false` | Enable persistence |
| persistence.size | string | `"1Gi"` | Size of persistent volume |
| persistence.storageClass | string | `""` | Storage class for persistent volume |
| reader.aof.enabled | bool | `false` | Enable the AOF reader |
| reader.aof.filepath | string | `"/tmp/.aof"` | Path to the AOF file |
| reader.aof.timestamp | int | `0` | Timestamp for AOF (subsecond) |
| reader.rdb.enabled | bool | `false` | Enable the RDB reader |
| reader.rdb.filepath | string | `"/tmp/dump.rdb"` | Path to the RDB file |
| reader.scan.address | string | `"127.0.0.1:6379"` | Source Redis address (when cluster is true, set address to one of the cluster nodes) |
| reader.scan.cluster | bool | `false` | Set to true if source is a Redis cluster |
| reader.scan.count | int | `1` | Number of keys to scan per iteration |
| reader.scan.dbs | list | `[]` | Specific databases to scan (e.g., [1,5,7]), leave empty to scan all |
| reader.scan.enabled | bool | `false` | Enable the scan reader |
| reader.scan.ksn | bool | `false` | Enable Redis keyspace notifications (KSN) subscription |
| reader.scan.scan | bool | `true` | Enable key scanning |
| reader.scan.secret.addressKey | string | `"address"` | Key in secret containing the full address (host:port) |
| reader.scan.secret.enabled | bool | `false` | Enable secret reference for source Redis |
| reader.scan.secret.hostKey | string | `""` | Key in secret containing just the host (alternative to addressKey) |
| reader.scan.secret.name | string | `""` | Name of existing secret containing source Redis credentials |
| reader.scan.secret.passwordKey | string | `"password"` | Key in secret containing the password (REQUIRED) |
| reader.scan.secret.portKey | string | `""` | Key in secret containing just the port (alternative to addressKey) |
| reader.scan.secret.usernameKey | string | `"username"` | Key in secret containing the username |
| reader.scan.tls | bool | `false` | Enable TLS for the source connection |
| reader.scan.username | string | `""` | Source Redis username (keep empty if not using ACL) |
| reader.sync.address | string | `"127.0.0.1:6379"` | Source Redis address (for clusters, specify any cluster node address) |
| reader.sync.cluster | bool | `false` | Set to true if the source is a Redis cluster |
| reader.sync.enabled | bool | `true` | Enable the sync reader |
| reader.sync.prefer_replica | bool | `false` | Prefer replica for sync (useful for reducing load on master) |
| reader.sync.secret.addressKey | string | `"address"` | Key in secret containing the full address (host:port) |
| reader.sync.secret.enabled | bool | `false` | Enable secret reference for source Redis |
| reader.sync.secret.hostKey | string | `""` | Key in secret containing just the host (alternative to addressKey) |
| reader.sync.secret.name | string | `""` | Name of existing secret containing source Redis credentials |
| reader.sync.secret.passwordKey | string | `"password"` | Key in secret containing the password (REQUIRED) |
| reader.sync.secret.portKey | string | `""` | Key in secret containing just the port (alternative to addressKey) |
| reader.sync.secret.usernameKey | string | `"username"` | Key in secret containing the username |
| reader.sync.sync_aof | bool | `true` | Sync AOF data from source |
| reader.sync.sync_rdb | bool | `true` | Sync RDB data from source |
| reader.sync.tls | bool | `false` | Enable TLS for the source connection |
| reader.sync.try_diskless | bool | `false` | Try diskless sync if source has repl-diskless-sync=yes |
| reader.sync.username | string | `""` | Source Redis username (keep empty if ACL is not in use) |
| replicaCount | int | `1` | Number of RedisShake replicas to deploy |
| secret.enabled | bool | `false` | Enable chart-managed secret |
| secret.name | string | `"redisshake-secret"` | Name of the chart-managed secret |
| secret.sourcePassword | string | `""` | Source Redis password (will be stored in Kubernetes secret) |
| secret.targetPassword | string | `""` | Target Redis password (will be stored in Kubernetes secret) |
| service.annotations | object | `{}` | Additional service annotations |
| service.enabled | bool | `true` | Enable service |
| service.type | string | `"ClusterIP"` | Service type |
| serviceAccount.annotations | object | `{}` | Additional service account annotations |
| serviceAccount.create | bool | `true` | Create service account |
| serviceAccount.enabled | bool | `false` | Enable service account |
| serviceAccount.name | string | `""` | Service account name |
| tolerations | list | `[]` | Pod tolerations |
| writer.file.enabled | bool | `false` | Enable the file writer |
| writer.file.filepath | string | `"/tmp/cmd.txt"` | Output file path |
| writer.file.type | string | `"cmd"` | Output format: cmd, aof, json (default cmd) |
| writer.redis.address | string | `"127.0.0.1:6380"` | Target Redis address (when cluster is true, set address to one of the cluster nodes) |
| writer.redis.cluster | bool | `false` | Set to true if target is a Redis cluster |
| writer.redis.enabled | bool | `true` | Enable the Redis writer |
| writer.redis.off_reply | bool | `false` | Turn off the server reply |
| writer.redis.secret.addressKey | string | `"address"` | Key in secret containing the full address (host:port) |
| writer.redis.secret.enabled | bool | `false` | Enable secret reference for target Redis |
| writer.redis.secret.hostKey | string | `""` | Key in secret containing just the host (alternative to addressKey) |
| writer.redis.secret.name | string | `""` | Name of existing secret containing target Redis credentials |
| writer.redis.secret.passwordKey | string | `"password"` | Key in secret containing the password (REQUIRED) |
| writer.redis.secret.portKey | string | `""` | Key in secret containing just the port (alternative to addressKey) |
| writer.redis.secret.usernameKey | string | `"username"` | Key in secret containing the username |
| writer.redis.tls | bool | `false` | Enable TLS for the target connection |
| writer.redis.username | string | `""` | Target Redis username (keep empty if not using ACL) |

## Usage Examples

### Basic Sync Mode
```yaml
mode: sync
reader:
  sync:
    enabled: true
    address: "source-redis:6379"
    password: "source-pass"  # Set as SHAKE_SRC_PASSWORD env var
writer:
  redis:
    enabled: true
    address: "target-redis:6379"
    password: "target-pass"  # Set as SHAKE_DST_PASSWORD env var
```

### Scan Mode with Filtering
```yaml
mode: scan
reader:
  scan:
    enabled: true
    address: "source-redis:6379"
    dbs: [0, 1]
    count: 1000
writer:
  redis:
    enabled: true
    address: "target-redis:6379"
filter:
  allow_key_prefix: ["user:", "product:"]
  block_key_suffix: [":tmp"]
```

### Restore from RDB
```yaml
mode: restore
reader:
  rdb:
    enabled: true
    filepath: "/data/dump.rdb"
writer:
  redis:
    enabled: true
    address: "target-redis:6379"
```

### Dump to File
```yaml
mode: dump
reader:
  sync:
    enabled: true
    address: "source-redis:6379"
writer:
  file:
    enabled: true
    filepath: "/data/dump.txt"
    type: "cmd"
```

### Using Existing Secrets
```yaml
mode: sync
reader:
  sync:
    enabled: true
    secret:
      enabled: true
      name: "source-redis-credentials"
      addressKey: "redis-host"
      usernameKey: "redis-user"
      passwordKey: "redis-pass"
writer:
  redis:
    enabled: true
    secret:
      enabled: true
      name: "target-redis-credentials"
      addressKey: "redis-host"
      usernameKey: "redis-user"
      passwordKey: "redis-pass"
```

### Using Separate Host and Port Keys
```yaml
mode: sync
reader:
  sync:
    enabled: true
    secret:
      enabled: true
      name: "source-redis-credentials"
      hostKey: "redis-host"        # Separate host key
      portKey: "redis-port"        # Separate port key
      usernameKey: "redis-user"
      passwordKey: "redis-pass"
writer:
  redis:
    enabled: true
    secret:
      enabled: true
      name: "target-redis-credentials"
      hostKey: "redis-host"        # Separate host key
      portKey: "redis-port"        # Separate port key
      usernameKey: "redis-user"
      passwordKey: "redis-pass"
```

## Monitoring & Troubleshooting

### Status Endpoint
When `advanced.status.enabled` is set to true, RedisShake provides a status endpoint:
```bash
kubectl port-forward deployment/my-redisshake 8080:8080
curl http://localhost:8080
```

### PProf Debugging
When `advanced.pprof.enabled` is set to true, RedisShake provides PProf debugging:
```bash
kubectl port-forward deployment/my-redisshake 6060:6060
go tool pprof http://localhost:6060/debug/pprof/heap
```

### Logs
```bash
kubectl logs -f deployment/my-redisshake
```

### Common Issues

1. **Connection refused**: Check Redis addresses and network connectivity
2. **Authentication failed**: Verify Redis passwords and ACL settings
3. **Permission denied**: Check file permissions for RDB/AOF files
4. **Memory issues**: Adjust `pipeline_count_limit` and buffer sizes

### Debug Mode
Enable debug logging:
```yaml
advanced:
  log_level: "debug"
```
