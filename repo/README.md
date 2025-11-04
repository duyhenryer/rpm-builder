# Repo Directory

**NOTE: This directory contains source code cloned from GitHub repositories.**

In production, code should be cloned here before building RPM.

## Structure

Each service should be cloned from its respective GitHub repository:

```bash
# Example: Clone repositories here
cd rpm-builder
git clone https://github.com/org/api-server.git repo/api-server
git clone https://github.com/org/user-api.git repo/user-api
git clone https://github.com/org/checkout-api.git repo/checkout-api
git clone https://github.com/org/voter-api.git repo/voter-api
```

## Current Contents (POC)

Code hiện có sẵn trong repo/:
- `api-server/` - API server source code (code mẫu POC)
- `user-api/` - User API source code (copy từ api-server)
- `checkout-api/` - Checkout API source code (copy từ api-server)
- `voter-api/` - Voter API source code (copy từ api-server)

**Lưu ý**: Trong production, mỗi service nên clone từ GitHub repository riêng.

## Build Process

The build script (`scripts/build.sh`) will:
1. **Auto-detect** tất cả services có `main.go` trong `repo/`
2. **Build binaries** từ mỗi `repo/{service}/`:
   - `repo/api-server/` → `repo/api-server/api-server` (binary)
   - `repo/user-api/` → `repo/user-api/user-api` (binary)
   - `repo/checkout-api/` → `repo/checkout-api/checkout-api` (binary)
   - `repo/voter-api/` → `repo/voter-api/voter-api` (binary)
3. **Copy binaries** to `apps/{service}/` (staging area)
4. **Copy everything** (binaries + configs) to `rpm/SOURCES/` (RPM input)
5. **Build RPM** in Docker container → `dist/micro-platform-*.rpm`

**Lưu ý**: RPM spec chỉ handle `user-api`, `checkout-api`, `voter-api` (đơn giản, tường minh)

## Important Notes

- ⚠️ **Code in this directory is typically NOT committed** to this RPM builder repo
- ✅ **Code should be cloned from GitHub** before building
- 📝 **Current `api-server/` is POC code** - replace with real repository in production

