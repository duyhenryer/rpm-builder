# Micro Platform - Single RPM Builder

.PHONY: help docker-build build clean

# Default target
help:
	@echo "Micro Platform - Available targets:"
	@echo ""
	@echo "  docker-build  - Build Docker image"
	@echo "  build         - Build single RPM with all services"
	@echo "  clean         - Clean build artifacts"
	@echo ""
	@echo "Examples:"
	@echo "  make build     # Build single RPM with all services"

# Build Docker image
docker-build:
	@echo "🐳 Building Docker image..."
	@docker build -t rpm-builder:latest .
	@echo "✅ Docker image built: rpm-builder:latest"

# Build single RPM with all services
build: docker-build
	@echo "🚀 Building Micro Platform (Single RPM)..."
	@chmod +x scripts/build.sh
	@./scripts/build.sh

# Clean up
clean:
	@echo "🧹 Cleaning up..."
	@rm -rf dist/
	@rm -rf build/
	@rm -rf rpm/BUILD rpm/BUILDROOT rpm/RPMS rpm/SRPMS rpm/SOURCES
	@rm -f apps/*/user-api apps/*/checkout-api apps/*/voter-api
	@echo "✅ Cleanup completed!"