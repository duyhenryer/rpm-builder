# My Service Platform - Single RPM Builder

.PHONY: help docker-build build test clean

# Default target
help:
	@echo "My Service Platform - Available targets:"
	@echo ""
	@echo "  docker-build  - Build Docker image"
	@echo "  build         - Build single RPM with all services"
	@echo "  test          - Test RPM installation"
	@echo "  clean         - Clean build artifacts"
	@echo ""
	@echo "Examples:"
	@echo "  make build     # Build single RPM with all services"
	@echo "  make test      # Test installation"

# Build Docker image
docker-build:
	@echo "🐳 Building Docker image..."
	@docker build -t rpm-builder:latest ./docker/
	@echo "✅ Docker image built: rpm-builder:latest"

# Build single RPM with all services
build: docker-build
	@echo "🚀 Building My Service Platform (Single RPM)..."
	@chmod +x scripts/build.sh
	@./scripts/build.sh

# Test RPM
test:
	@echo "🧪 Testing RPM installation..."
	@chmod +x scripts/test-simple.sh
	@./scripts/test-simple.sh

# Test RPM (manual instructions)
test-manual:
	@echo "🧪 Manual RPM installation test..."
	@echo "📦 Prerequisites: dnf install nginx"
	@echo "📦 Install: rpm -ivh dist/my-service-*.rpm"
	@echo "🌐 Access: http://localhost:80/"
	@echo "🔍 Health: http://localhost:80/health"
	@echo "🔧 Control: systemctl start/stop my-service-all.target"

# Clean up
clean:
	@echo "🧹 Cleaning up..."
	@rm -rf dist/
	@rm -rf build/
	@rm -rf rpm/BUILD rpm/BUILDROOT rpm/RPMS rpm/SRPMS rpm/SOURCES
	@rm -f apps/*/hello-api apps/*/checkout-api
	@echo "✅ Cleanup completed!"