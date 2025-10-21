Name:           my-service
Version:        1.0.0
Release:        1
Summary:        My Service Platform - All Services
License:        MIT
URL:            https://github.com/duyhenryer/rpm-builder
Source0:        hello-api
Source1:        checkout-api
Source2:        my-service.conf
Source3:        my-service-infra.target
Source4:        my-service-all.target
Source5:        my-service-hello-api.service
Source6:        my-service-checkout-api.service
BuildRequires:  golang >= 1.21
Requires:       nginx >= 1.20, systemd

%description
Complete service platform with:
- hello-api (port 8080)
- checkout-api (port 8081)  
- nginx reverse proxy (port 80)

This package provides a unified platform with all services bundled together.
Install once and get all services running with proper orchestration.

%prep
# No source preparation needed - we're using pre-built binaries

%build
# No build step needed - we're using pre-built binaries

%install
# Create directory structure
mkdir -p %{buildroot}/opt/my-service/apps/hello-api/
mkdir -p %{buildroot}/opt/my-service/apps/checkout-api/
mkdir -p %{buildroot}/etc/nginx/conf.d/
mkdir -p %{buildroot}/usr/lib/systemd/system/

# Copy Go binaries
cp %{_sourcedir}/hello-api %{buildroot}/opt/my-service/apps/hello-api/hello-api
cp %{_sourcedir}/checkout-api %{buildroot}/opt/my-service/apps/checkout-api/checkout-api

# Copy nginx config (nginx binary from repo)
cp %{_sourcedir}/my-service.conf %{buildroot}/etc/nginx/conf.d/my-service.conf

# Copy systemd files
cp %{_sourcedir}/my-service-infra.target %{buildroot}/usr/lib/systemd/system/
cp %{_sourcedir}/my-service-all.target %{buildroot}/usr/lib/systemd/system/
cp %{_sourcedir}/my-service-hello-api.service %{buildroot}/usr/lib/systemd/system/
cp %{_sourcedir}/my-service-checkout-api.service %{buildroot}/usr/lib/systemd/system/

%files
%defattr(-,root,root,-)
/opt/my-service/**
/etc/nginx/conf.d/my-service.conf
/usr/lib/systemd/system/my-service-*

%pre
# Check if upgrading or installing
if [ $1 -gt 1 ]; then
    echo "%pre upgrade"
    echo "Stopping services for upgrade..."
    systemctl stop my-service-all.target || true
    systemctl disable my-service-all.target || true
else
    echo "%pre install"
    echo "Checking port availability..."
fi

# Check port availability
portCheck=$(ss -tuln | grep -E ":(80|8080|8081) " || true)
if [ -n "$portCheck" ]; then
    echo "[ERROR] Required ports (80, 8080, 8081) are not available:" >&2
    echo "$portCheck" >&2
    echo "Please stop services using these ports first." >&2
    exit 1
fi

# Create log directories
mkdir -p /var/log/my-service/hello-api
mkdir -p /var/log/my-service/checkout-api
mkdir -p /var/log/my-service/nginx
chown -R nobody:nobody /var/log/my-service

%post
# Set permissions
chmod +x /opt/my-service/apps/hello-api/hello-api
chmod +x /opt/my-service/apps/checkout-api/checkout-api

# Reload nginx to pick up new config
systemctl reload nginx || true

# Reload systemd and start services
systemctl daemon-reload

if [ $1 -gt 1 ]; then
    echo "%post upgrade"
    systemctl enable my-service-all.target
    systemctl start my-service-all.target
else
    echo "%post install"
    systemctl enable my-service-all.target
    systemctl start my-service-all.target
fi

echo "My Service Platform installed successfully!"

%preun
if [ $1 -eq 0 ]; then
    echo "%preun remove"
    echo "Stopping all services..."
    systemctl stop my-service-all.target || true
    systemctl disable my-service-all.target || true
    echo "Removing log directories..."
    rm -rf /var/log/my-service
else
    echo "%preun upgrade"
fi

%postun
if [ $1 -eq 0 ]; then
    echo "%postun remove"
    systemctl daemon-reload
    echo "My Service Platform removed successfully"
else
    echo "%postun upgrade"
    systemctl daemon-reload
fi

%changelog

