# Micro Platform - RPM Builder

A complete service platform packaged as a single RPM containing multiple Go APIs, Nginx reverse proxy configuration, and systemd orchestration.

## Overview

This project demonstrates how to build a unified RPM package with:
- **Multiple Go APIs**: Each service has its own binary built from source code
- **Configuration Management**: .properties files with shared configs following proven patterns
- **Nginx reverse proxy**: Routes traffic on port 80
- **Redis cache**: In-memory caching on port 6379
- **Systemd orchestration**: Target-based service management with EnvironmentFile directives
- **Docker-based build**: Rocky Linux 9 environment
- **Single deployment**: One RPM installs everything

## Project Structure

```
rpm-builder/
├── repo/                    # Source code (available or cloned from GitHub)
│   ├── api-server/          # API server source code
│   │   ├── main.go
│   │   ├── config/
│   │   ├── handlers/
│   │   └── go.mod
│   ├── user-api/            # User API source code
│   │   ├── main.go
│   │   ├── config/
│   │   ├── handlers/
│   │   └── go.mod
│   ├── checkout-api/        # Checkout API source code
│   │   ├── main.go
│   │   ├── config/
│   │   ├── handlers/
│   │   └── go.mod
│   └── voter-api/           # Voter API source code
│       ├── main.go
│       ├── config/
│       ├── handlers/
│       └── go.mod
│
├── apps/                    # Built applications (binaries + configs ready for RPM)
│   ├── api-server/
│   │   ├── api-server       # Binary (built from repo/api-server/)
│   │   └── api-server.properties
│   ├── user-api/
│   │   ├── user-api         # Binary (built from repo/user-api/)
│   │   └── user-api.properties  # Service-specific config
│   ├── checkout-api/
│   │   ├── checkout-api     # Binary (built from repo/checkout-api/)
│   │   └── checkout-api.properties
│   ├── voter-api/
│   │   ├── voter-api        # Binary (built from repo/voter-api/)
│   │   └── voter-api.properties
│   └── conf-shared/         # Shared configuration files
│       ├── env.properties
│       └── redis.properties
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
│   │       ├── micro-platform-api-server.service
│   │       ├── micro-platform-user-api.service
│   │       ├── micro-platform-checkout-api.service
│   │       ├── micro-platform-voter-api.service
│   │       ├── micro-platform-infra.target
│   │       └── micro-platform-all.target
│   └── SOURCES/            # Auto-generated during build
├── Dockerfile              # Rocky Linux 9 + rpmbuild tools
├── scripts/
│   └── build.sh            # Main build script
├── dist/                   # Output RPM
│   └── micro-platform-1.0.0-1.x86_64.rpm
├── Makefile                # Build automation
├── README.md               # This documentation
└── .gitattributes          # Git line ending configuration
```

## Quick Start

```bash
# 1. Clone source code repos (if not already done)
# Code from GitHub repos should be in repo/ directory
# Example: git clone github.com/org/api-server repo/api-server

# 2. Build single RPM with all services
make build

# 3. Clean build artifacts
make clean
```

**Note**: The build script expects source code to be in `repo/{service}/`. If using separate GitHub repos, clone them to `repo/` before building.

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
### How Dependencies Work

**With dnf/yum (Recommended):**
```bash
dnf install micro-platform-1.0.0-1.x86_64.rpm
# ✅ Automatically installs nginx, redis, and all dependencies
```



## Installation & Usage

## Installation Methods

### Method 1: Using dnf (Recommended - Auto Install Dependencies)

```bash
# Single command - nginx installed automatically
dnf install dist/micro-platform-1.0.0-1.x86_64.rpm
```

✅ **Advantages:**
- Automatically installs nginx and redis if not present
- Resolves all dependencies automatically
- Follows standard RPM dependency management practices

### Method 2: Using rpm (Manual Dependency Management)

```bash
# Step 1: Install dependencies manually first
dnf install nginx redis

# Step 2: Install RPM
rpm -ivh dist/micro-platform-1.0.0-1.x86_64.rpm
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

### Access Services

After installation, services are available at:

- **Platform Landing**: `http://server/`
- **User API (via nginx)**: `http://server/user/`
- **Checkout API (via nginx)**: `http://server/checkout/`
- **Voter API (via nginx)**: `http://server/vote/`
- **Health Check**: `http://server/health`
- **Direct APIs**: `http://server:8080/`, `http://server:8081/`, `http://server:8082/`
- **Redis**: `localhost:6379` (local access only)

## File Locations After Install

```
/opt/micro-platform/apps/
├── user-api/
│   ├── user-api            # Service binary
│   └── user-api.properties # Service config
├── checkout-api/
│   ├── checkout-api        # Service binary
│   └── checkout-api.properties
├── voter-api/
│   ├── voter-api           # Service binary
│   └── voter-api.properties
└── conf-shared/                   # Shared configuration
    ├── env.properties
    └── redis.properties

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

1. **Source Code**: Code from GitHub repos should be cloned/placed in `repo/` directory
2. **Docker Environment**: Rocky Linux 9 with rpmbuild tools
3. **Go Compilation**: Build binaries from `repo/{service}/`
4. **Copy to apps/**: Copy built binaries + configs to `apps/{service}/`
5. **Configuration**: Copy .properties files (shared and app-specific)
6. **RPM Creation**: Single package with all services and configurations
7. **Dependencies**: Requires nginx >= 1.20, redis >= 6.0, and systemd

### Build Flow

```
repo/{service}/          → Build → apps/{service}/{binary}
+ configs                → Copy  → apps/{service}/{config}
                        ↓
                    RPM SOURCES
                        ↓
                    RPM Package
```

## Configuration Management

The platform uses `.properties` files for configuration following proven patterns.

### Configuration Priority (Lowest to Highest)

**IMPORTANT**: In systemd service files, the order of `EnvironmentFile` directives determines priority!

**Systemd loads EnvironmentFile directives from top to bottom. Files loaded later will override variables with the same name from files loaded earlier.**

**Order in service file (top to bottom) = Priority (lowest → highest):**

1. **Shared configs** (lowest priority - lines 14-15):
   ```ini
   EnvironmentFile=/opt/micro-platform/apps/conf-shared/env.properties
   EnvironmentFile=/opt/micro-platform/apps/conf-shared/redis.properties
   ```
   - Loaded first → used as default values for all services

2. **App-specific config** (higher priority - line 18):
   ```ini
   EnvironmentFile=/opt/micro-platform/apps/{app-name}/{app-name}.properties
   ```
   - Loaded next → overrides shared configs if variable names match

3. **Override file** (highest priority - line 21):
   ```ini
   EnvironmentFile=-/opt/micro-platform/apps/{app-name}/{app-name}.override
   ```
   - Loaded last → overrides all, used for local testing/development
   - The `-` prefix means optional (won't fail if file doesn't exist)

4. **Default values in code** (fallback - if not present in config files)

### Concrete Example:

If you have:
- `conf-shared/env.properties`: `GO_ENV="production"`
- `user-api/user-api.properties`: `GO_ENV="staging"`
- `user-api/user-api.override`: `GO_ENV="development"`

**Result**: `GO_ENV="development"` (taken from override file - highest priority)

### Example in Service File

**Order in file = Priority (lowest → highest):**

```ini
[Service]
# Step 1: Load shared configs (LOWEST PRIORITY - loaded first)
EnvironmentFile=/opt/micro-platform/apps/conf-shared/env.properties
EnvironmentFile=/opt/micro-platform/apps/conf-shared/redis.properties

# Step 2: Load app-specific config (HIGHER PRIORITY - overrides shared)
EnvironmentFile=/opt/micro-platform/apps/user-api/user-api.properties

# Step 3: Load override file (HIGHEST PRIORITY - overrides all)
EnvironmentFile=-/opt/micro-platform/apps/user-api/user-api.override
```

**How it works:**
- Systemd reads each `EnvironmentFile` directive in order from top to bottom
- Environment variables are set/updated in sequence
- If variable names match, the later value replaces the earlier value
- **Result**: Variables from the last file (override) will have the final value

### Configuration Variables

**Service Configuration** (app-specific):
- `GO_PORT` - Port number (e.g., "8080")
- `GO_SERVICE_NAME` - Service name (e.g., "user-api")
- `GO_ENDPOINT_PATH` - Endpoint path (e.g., "/user")
- `GO_ENDPOINT_NAME` - Endpoint name (e.g., "user")
- `LOGGER_FILE_NAME` - Log file name

**Shared Configuration** (from `apps/conf-shared/`):
- `GO_ENV` - Environment (e.g., "production", "development")
- `REDIS_ADDR` - Redis address (e.g., "localhost:6379")
- `REDIS_PASSWORD` - Redis password
- `REDIS_DB` - Redis database number
- `REDIS_USE_SSL` - Whether to use SSL for Redis

### Example Configuration Files

**App-specific** (`apps/user-api/user-api.properties`):
```properties
GO_PORT="8080"
GO_SERVICE_NAME="user-api"
GO_ENDPOINT_PATH="/user"
GO_ENDPOINT_NAME="user"
LOGGER_FILE_NAME="user-api.log"
```

**Shared** (`apps/conf-shared/redis.properties`):
```properties
REDIS_ADDR="localhost:6379"
REDIS_PASSWORD=""
REDIS_DB="0"
REDIS_USE_SSL="false"
```

**Shared** (`apps/conf-shared/env.properties`):
```properties
GO_ENV="production"
```

## Adding New APIs

To add a new API (e.g., `order-api`):

### 1. Clone Repository (or place code)

Clone the service repository to `repo/`:
```bash
git clone github.com/org/order-api repo/order-api
```

### 2. Create Properties File

Create `apps/order-api/order-api.properties`:
```properties
GO_PORT="8083"
GO_SERVICE_NAME="order-api"
GO_ENDPOINT_PATH="/order"
GO_ENDPOINT_NAME="order"
LOGGER_FILE_NAME="order-api.log"
```

### 3. Build Script (Auto-detect)

**No need to update the build script!** The script automatically detects and builds all services in `repo/`:
- Automatically finds all directories in `repo/` containing `main.go`
- Automatically builds and copies binaries
- Just ensure the code in `repo/order-api/` has `main.go`

### 4. Create Systemd Service

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

# Load shared configurations first
EnvironmentFile=/opt/micro-platform/apps/conf-shared/env.properties
EnvironmentFile=/opt/micro-platform/apps/conf-shared/redis.properties

# Load app-specific configuration (can override shared)
EnvironmentFile=/opt/micro-platform/apps/order-api/order-api.properties

# Optional override file (won't fail if missing)
EnvironmentFile=-/opt/micro-platform/apps/order-api/order-api.override

ExecStart=/opt/micro-platform/apps/order-api/order-api
Restart=always
RestartSec=10
StandardOutput=append:/var/log/micro-platform/order-api/stdout.log
StandardError=append:/var/log/micro-platform/order-api/stderr.log
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=true
ReadWritePaths=/var/log/micro-platform/order-api

[Install]
WantedBy=multi-user.target
```

### 5. Update RPM Spec (Manual)

Edit `rpm/specs/micro-platform.spec`:
```spec
# Update %install section
mkdir -p %{buildroot}/opt/micro-platform/apps/order-api/
cp %{_sourcedir}/order-api/order-api.properties %{buildroot}/opt/micro-platform/apps/order-api/

# Properties files are already included via wildcard in %files section
```

### 6. Update Nginx Config (Optional)

Add to `infra/nginx/micro-platform.conf`:
```nginx
upstream order_api {
    server 127.0.0.1:8083;
}

location /order/ {
    proxy_pass http://order_api/;
    # ... proxy headers
}
```

### 7. Update Systemd Targets

Update `micro-platform-all.target`:
```ini
Wants=micro-platform-user-api.service micro-platform-checkout-api.service micro-platform-voter-api.service micro-platform-order-api.service
```