# POC - RPM Builder

A complete service platform packaged as a single RPM containing multiple Go APIs, Nginx reverse proxy configuration, and systemd orchestration.

## Overview

This project demonstrates how to build a unified RPM package.

## Project Structure

```
rpm-builder/
├── apps/                    # Go applications source code
│   ├── hello-api/
│   │   ├── main.go         # HTTP server (port 8080)
│   │   └── go.mod
│   └── checkout-api/
│       ├── main.go         # HTTP server (port 8081)
│       └── go.mod
│
├── infra/                   # Infrastructure configurations
│   └── nginx/
│       └── my-service.conf # Nginx reverse proxy config
│
├── rpm/
│   ├── specs/
│   │   └── my-service.spec # Single RPM specification
│   ├── files/
│   │   └── systemd/
│   │       ├── my-service-hello-api.service
│   │       ├── my-service-checkout-api.service
│   │       ├── my-service-infra.target
│   │       └── my-service-all.target
│   └── SOURCES/            # Auto-generated during build
│
├── docker/
│   └── Dockerfile          # Rocky Linux 9 + rpmbuild tools
│
├── scripts/
│   └── build.sh            # Main build script
│
├── dist/                   # Output RPM
│   └── my-service-1.0.0-1.x86_64.rpm
│
├── build/                  # Intermediate build artifacts
│   └── bin/
│
├── Makefile                # Build automation
└── README.md               # This documentation
```

## Quick Start

```bash
# Build single RPM with all services
make build

# Show manual testing instructions
make test-manual

# Clean build artifacts
make clean
```

## Architecture

### Systemd Service Hierarchy

```
my-service-all.target (Master orchestrator)
    ├── my-service-infra.target
    │   └── nginx.service (system service)
    ├── my-service-hello-api.service
    └── my-service-checkout-api.service
```

### Port Mapping

| Service | Port | Description |
|---------|------|-------------|
| Nginx | 80 | Reverse proxy (main entry point) |
| hello-api | 8080 | Direct API access |
| checkout-api | 8081 | Direct API access |

## Installation & Usage

### Prerequisites

```bash
# Install nginx (required dependency)
dnf install nginx
```

### Install RPM

```bash
# Install the platform
rpm -ivh dist/my-service-1.0.0-1.x86_64.rpm
```

### Control Services

```bash
# Start all services
systemctl start my-service-all.target

# Stop all services
systemctl stop my-service-all.target

# Check status
systemctl status my-service-all.target

# View logs
journalctl -u my-service-hello-api.service
journalctl -u my-service-checkout-api.service
```


## File Locations After Install

```
/opt/my-service/apps/
├── hello-api/hello-api
└── checkout-api/checkout-api

/etc/nginx/conf.d/my-service.conf

/usr/lib/systemd/system/
├── my-service-hello-api.service
├── my-service-checkout-api.service
├── my-service-infra.target
└── my-service-all.target

/var/log/my-service/
├── hello-api/
├── checkout-api/
└── nginx/
```

## Adding New APIs

To add a new API (e.g., `user-api`):

### 1. Create Application

```bash
mkdir -p apps/user-api
cd apps/user-api

# Create main.go (HTTP server on port 8082)
# Create go.mod
```

### 2. Update Build Script

Edit `scripts/build.sh`:
```bash
# Add to the loop
for app in hello-api checkout-api user-api; do
    # ... existing code
done
```

### 3. Create Systemd Service

Create `rpm/files/systemd/my-service-user-api.service`:
```ini
[Unit]
Description=My Service - User API
After=my-service-infra.target
Requires=my-service-infra.target
PartOf=my-service-all.target

[Service]
Type=exec
User=nobody
Group=nobody
WorkingDirectory=/opt/my-service/apps/user-api
ExecStart=/opt/my-service/apps/user-api/user-api
Restart=always
RestartSec=10
StandardOutput=append:/var/log/my-service/user-api/stdout.log
StandardError=append:/var/log/my-service/user-api/stderr.log

[Install]
WantedBy=multi-user.target
```

### 4. Update RPM Spec

Edit `rpm/specs/my-service.spec`:
```spec
# Add new Source
Source7:        user-api

# Update %install section
mkdir -p %{buildroot}/opt/my-service/apps/user-api/
cp %{_sourcedir}/user-api %{buildroot}/opt/my-service/apps/user-api/user-api

# Update %files section
/opt/my-service/apps/user-api/**

# Update %post section
chmod +x /opt/my-service/apps/user-api/user-api
```

### 5. Update Nginx Config

Add to `infra/nginx/my-service.conf`:
```nginx
upstream user_api {
    server 127.0.0.1:8082;
}

location /user/ {
    proxy_pass http://user_api/;
    # ... proxy headers
}
```

### 6. Update Systemd Targets

Update `my-service-all.target`:
```ini
Wants=my-service-hello-api.service my-service-checkout-api.service my-service-user-api.service
```

## Troubleshooting

### Common Issues

**Port already in use:**
```bash
# Check port usage
ss -tuln | grep -E ":(80|8080|8081)"
# Stop conflicting services
systemctl stop <service-name>
```

**Nginx not installed:**
```bash
# Install nginx first
dnf install nginx
# Then install RPM
rpm -ivh my-service-1.0.0-1.x86_64.rpm
```

**Service not starting:**
```bash
# Check service status
systemctl status my-service-all.target
# Check logs
journalctl -u my-service-hello-api.service -f
```

**Nginx config not loaded:**
```bash
# Test nginx config
nginx -t
# Reload nginx
systemctl reload nginx
```

### Log Locations

- **Service logs**: `/var/log/my-service/{hello-api,checkout-api,nginx}/`
- **Systemd logs**: `journalctl -u my-service-*.service`
- **Nginx logs**: `/var/log/nginx/`

## Features

- ✅ **Single RPM deployment**: Install once, get all services
- ✅ **Multiple Go APIs**: Easy to add new services
- ✅ **Nginx reverse proxy**: Professional routing
- ✅ **Systemd orchestration**: Target-based service management
- ✅ **Docker build environment**: Consistent builds
- ✅ **Security hardening**: Non-root user, restricted permissions
- ✅ **Health checks**: Built-in monitoring endpoints
- ✅ **Graceful shutdown**: Proper signal handling
- ✅ **Extensible architecture**: Easy to add new APIs

## Development

### Local Development

```bash
# Build and test locally
make build

# Check RPM contents
rpm -qlp dist/my-service-1.0.0-1.x86_64.rpm

# Test installation in container
docker run -it --rm -v $(pwd)/dist:/dist rockylinux:9 bash
dnf install nginx
rpm -ivh /dist/my-service-1.0.0-1.x86_64.rpm
```

### Build Dependencies

- Docker (for build environment)
- Go 1.21+ (for application compilation)
- Rocky Linux 9 (build environment)

