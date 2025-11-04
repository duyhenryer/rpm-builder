# Micro Platform - RPM Builder

A complete service platform packaged as a single RPM containing multiple Go APIs, Nginx reverse proxy configuration, and systemd orchestration.

## Overview

This project demonstrates how to build a unified RPM package with:
- **Multiple Go APIs**: `user-api` (port 8080), `checkout-api` (port 8081), `voter-api` (port 8082)
- **Nginx reverse proxy**: Routes traffic on port 80
- **Redis cache**: In-memory caching on port 6379
- **Systemd orchestration**: Target-based service management
- **Docker-based build**: Rocky Linux 9 environment
- **Single deployment**: One RPM installs everything

## Project Structure

```
rpm-builder/
├── apps/                    # Go applications source code
│   ├── user-api/
│   │   ├── main.go         # HTTP server (port 8080)
│   │   └── go.mod
│   ├── checkout-api/
│   │   ├── main.go         # HTTP server (port 8081)
│   │   └── go.mod
│   └── voter-api/
│       ├── main.go         # HTTP server (port 8082)
│       └── go.mod
│
├── infra/                   # Infrastructure configurations
│   ├── nginx/
│   │   └── micro-platform.conf # Nginx reverse proxy config
│   └── redis/
│       └── micro-platform-redis.conf # Redis cache configuration
│
├── rpm/
│   ├── specs/
│   │   └── micro-platform.spec # Single RPM specification
│   ├── files/
│   │   └── systemd/
│   │       ├── micro-platform-user-api.service
│   │       ├── micro-platform-checkout-api.service
│   │       ├── micro-platform-voter-api.service
│   │       ├── micro-platform-infra.target
│   │       └── micro-platform-all.target
│   └── SOURCES/            # Auto-generated during build
│
├── Dockerfile              # Rocky Linux 9 + rpmbuild tools
│
├── scripts/
│   └── build.sh            # Main build script
│
├── dist/                   # Output RPM
│   └── micro-platform-1.0.0-1.x86_64.rpm
│
├── build/                  # Intermediate build artifacts
│   └── bin/
│
├── Makefile                # Build automation
├── README.md               # This documentation
└── .gitattributes          # Git line ending configuration
```

## Quick Start

```bash
# Build single RPM with all services
make build

# Clean build artifacts
make clean
```

## Available Makefile Targets

| Target | Description |
|--------|-------------|
| `make help` | Show help menu |
| `make docker-build` | Build Docker image (rpm-builder:latest) |
| `make build` | Build single RPM (auto-calls docker-build) |
| `make clean` | Clean all build artifacts |

## Architecture

### Systemd Service Hierarchy

```
micro-platform-all.target (Master orchestrator)
    ├── micro-platform-infra.target
    │   ├── nginx.service (system service)
    │   └── redis.service (system service)
    ├── micro-platform-user-api.service
    ├── micro-platform-checkout-api.service
    └── micro-platform-voter-api.service
```

### Port Mapping

| Service | Port | Description |
|---------|------|-------------|
| Nginx | 80 | Reverse proxy (main entry point) |
| Redis | 6379 | In-memory cache |
| user-api | 8080 | Direct API access |
| checkout-api | 8081 | Direct API access |
| voter-api | 8082 | Direct API access |


### How Dependencies Work

**With dnf/yum (Recommended):**
```bash
dnf install micro-platform-1.0.0-1.x86_64.rpm
# Automatically installs nginx, redis, and all dependencies
```

## Installation & Usage

## Installation

### Using dnf (Recommended - Auto Install Dependencies)

```bash
# Single command - nginx installed automatically
dnf install dist/micro-platform-1.0.0-1.x86_64.rpm
```

✅ **Advantages:**
- More control over nginx and redis versions
- Better for production deployments
- Explicit dependency management

### Install RPM

**Recommended: Using dnf**
```bash
# Automatically installs nginx, redis, and all dependencies
dnf install dist/micro-platform-1.0.0-1.x86_64.rpm

# Start services
systemctl start micro-platform-all.target
```

### Control Services

```bash
# Start all services
systemctl start micro-platform-all.target

# Stop all services
systemctl stop micro-platform-all.target

# Check status
systemctl status micro-platform-all.target

# View logs
journalctl -u micro-platform-user-api.service
journalctl -u micro-platform-checkout-api.service
journalctl -u micro-platform-voter-api.service
journalctl -u redis.service
journalctl -u nginx.service
```

## File Locations After Install

```
/opt/micro-platform/apps/
├── user-api/user-api
├── checkout-api/checkout-api
└── voter-api/voter-api

/etc/nginx/conf.d/micro-platform.conf
/etc/redis/micro-platform-redis.conf

/usr/lib/systemd/system/
├── micro-platform-user-api.service
├── micro-platform-checkout-api.service
├── micro-platform-voter-api.service
├── micro-platform-infra.target
└── micro-platform-all.target

/var/log/micro-platform/
├── user-api/
├── checkout-api/
├── voter-api/
└── nginx/
```

## Build Process

1. **Docker Environment**: Rocky Linux 9 with rpmbuild tools
2. **Go Compilation**: Build static binaries for all APIs (user-api, checkout-api, voter-api)
3. **RPM Creation**: Single package with all services and configurations
4. **Dependencies**: Requires nginx >= 1.20, redis >= 6.0, and systemd

## Adding New APIs

To add a new API (e.g., `order-api`):

### 1. Create Application

```bash
mkdir -p apps/order-api
cd apps/order-api

# Create main.go (HTTP server on port 8082)
# Create go.mod
```

### 2. Update Build Script

Edit `scripts/build.sh`:
```bash
# Update the apps array
apps=("user-api" "checkout-api" "voter-api" "order-api")
```

### 3. Create Systemd Service

Create `rpm/files/systemd/micro-platform-order-api.service`:
```ini
[Unit]
Description=Micro Platform - Order API
After=micro-platform-infra.target
Requires=micro-platform-infra.target
PartOf=micro-platform-all.target

[Service]
Type=exec
User=nobody
Group=nobody
WorkingDirectory=/opt/micro-platform/apps/order-api
ExecStart=/opt/micro-platform/apps/order-api/order-api
Restart=always
RestartSec=10
StandardOutput=append:/var/log/micro-platform/order-api/stdout.log
StandardError=append:/var/log/micro-platform/order-api/stderr.log

[Install]
WantedBy=multi-user.target
```

### 4. Update RPM Spec

Edit `rpm/specs/micro-platform.spec`:
```spec
# Add new Source
Source7:        order-api

# Update %install section
mkdir -p %{buildroot}/opt/micro-platform/apps/order-api/
cp %{_sourcedir}/order-api %{buildroot}/opt/micro-platform/apps/order-api/order-api

# Update %files section
/opt/micro-platform/apps/order-api/**

# Update %post section
chmod +x /opt/micro-platform/apps/order-api/order-api
```

### 5. Update Nginx Config

Add to `infra/nginx/micro-platform.conf`:
```nginx
upstream order_api {
    server 127.0.0.1:8082;
}

location /order/ {
    proxy_pass http://order_api/;
    # ... proxy headers
}
```

### 6. Update Systemd Targets

Update `micro-platform-all.target`:
```ini
Wants=micro-platform-user-api.service micro-platform-checkout-api.service micro-platform-voter-api.service micro-platform-order-api.service
```
