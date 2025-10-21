#!/bin/bash

# Build Single RPM Script
# Builds all Go apps and creates ONE RPM package

set -e

echo "🚀 Building My Service Platform..."

# Create dist directory
mkdir -p dist

# Build all Go applications
echo "📝 Building Go applications..."
for app in hello-api checkout-api; do
    echo "  Building $app..."
    cd apps/$app
    go mod tidy
    go build -o $app main.go
    mkdir -p ../../build/bin
    mv $app ../../build/bin/
    cd ../..
done

# Create SOURCES directory
mkdir -p rpm/SOURCES

# Copy all binaries to SOURCES
echo "📦 Preparing RPM sources..."
cp build/bin/* rpm/SOURCES/

# Copy nginx config
cp infra/nginx/my-service.conf rpm/SOURCES/

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
            specs/my-service.spec
        
        # Copy RPM to dist
        find RPMS -name "*.rpm" -exec cp {} /workspace/dist/ \;
    '

echo "✅ Single RPM built:"
ls -la dist/my-service-*.rpm

echo ""
echo "🎉 My Service Platform RPM created!"
echo "📦 Install: rpm -ivh dist/my-service-*.rpm"
echo "🌐 Access: http://localhost:80/"
echo "🔧 Control: systemctl start/stop my-service-all.target"
echo ""
echo "Note: nginx must be installed separately:"
echo "  dnf install nginx"
