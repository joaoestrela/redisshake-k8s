# RedisShake on Kubernetes

Repository dedicated for how to run [RedisShake](https://github.com/alibaba/RedisShake) on Kubernetes. RedisShake is a powerful tool for Redis data migration and synchronization.

## Documentation
- [RedisShake Project](https://github.com/alibaba/RedisShake)
- [RedisShake Official Docs](https://tair-opensource.github.io/RedisShake/)
- [Helm Chart Documentation](./helm/README.md)

## Scripts

This repository includes useful scripts for Redis operations and monitoring:

- **[Data Consistency Checker](./scripts/README.md)**: A bash script to check data consistency between two Redis instances across all databases. Useful for replication monitoring, migration validation, backup verification, load balancer testing, and disaster recovery scenarios.

All scripts are located in the [`scripts/`](./scripts/) directory with comprehensive documentation.

## License

This repository is licensed under the MIT License. See [LICENSE](./LICENSE) for details.
