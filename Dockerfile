FROM rockylinux:9

# Install build dependencies
RUN dnf update -y && \
    dnf install -y \
    rpm-build \
    rpmdevtools \
    golang \
    make \
    git \
    wget \
    systemd \
    && dnf clean all

# Set up rpmbuild environment
RUN rpmdev-setuptree

# Create workspace directory
WORKDIR /workspace

# Set environment variables
ENV GOPROXY=direct
ENV CGO_ENABLED=0
ENV GOOS=linux
ENV GOARCH=amd64

# Create non-root user for building
RUN useradd -m -s /bin/bash builder && \
    usermod -aG wheel builder

# Set up build environment
RUN mkdir -p /workspace/dist && \
    chown -R builder:builder /workspace /home/builder

# Switch to builder user
USER builder

# Default command
CMD ["/bin/bash"]

