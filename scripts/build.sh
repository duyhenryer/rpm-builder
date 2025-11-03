#!/bin/bash

# Build Single RPM Script
# Builds all Go apps and creates ONE RPM package

set -e

echo "🚀 Building Micro Platform..."

# Create dist directory
mkdir -p dist

# Build all Go applications
# Array of applications to build (easy to maintain and extend)
apps=("user-api" "checkout-api" "voter-api")

echo "📝 Building Go applications..."
for app in "${apps[@]}"; do
    echo "  Building $app..."
    cd "apps/$app"
    go mod tidy
    go build -o "$app" main.go
    mkdir -p ../../build/bin
    mv "$app" ../../build/bin/
    cd ../..
done

# Create SOURCES directory
mkdir -p rpm/SOURCES

# Copy all binaries to SOURCES
echo "📦 Preparing RPM sources..."
cp build/bin/* rpm/SOURCES/

# Copy nginx config
cp infra/nginx/micro-platform.conf rpm/SOURCES/

# Copy redis config
cp infra/redis/micro-platform-redis.conf rpm/SOURCES/

# Copy systemd files
cp rpm/files/systemd/* rpm/SOURCES/

# Build RPM in Docker
echo "📦 Building single RPM..."
docker run --rm \
    -v "$(pwd)/rpm/SOURCES:/workspace/SOURCES" \
    -v "$(pwd)/rpm/specs:/workspace/specs" \
    -v "$(pwd)/dist:/workspace/dist" \
    -w /workspace \
    rpm-builder:latest \
    bash -c '
        rpmbuild -bb \
            --define "_sourcedir /workspace/SOURCES" \
            --define "_specdir /workspace/specs" \
            --define "_builddir /workspace/BUILD" \
            --define "_srcrpmdir /workspace/SRPMS" \
            --define "_rpmdir /workspace/RPMS" \
            --define "_buildrootdir /workspace/BUILDROOT" \
            specs/micro-platform.spec
        
        # Copy RPM to dist
        find RPMS -name "*.rpm" -exec cp {} /workspace/dist/ \;
    '

echo "✅ Single RPM built:"
ls -la dist/micro-platform-*.rpm

echo ""
echo "🎉 Micro Platform RPM created!"
echo "📦 Install: rpm -ivh dist/micro-platform-*.rpm"
echo "🌐 Access: http://localhost:80/"
echo "🔧 Control: systemctl start/stop micro-platform-all.target"