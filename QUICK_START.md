# IBM Verify Access Docker Compose - Quick Start Guide

This is a condensed quick-start guide for experienced users. For detailed instructions, see [`DOCKER_COMPOSE_DEPLOYMENT_GUIDE.md`](DOCKER_COMPOSE_DEPLOYMENT_GUIDE.md).

## Prerequisites Check

```bash
# Verify required tools
docker --version          # Should be 20.10+
docker-compose --version  # Should be 1.29+ or V2
openssl version          # Required for certificate generation
```

## Quick Deployment (5 Steps)

### 1. Create Keystores

```bash
cd /root/ivia/verify-access-container-deployment
./common/create-ldap-and-postgres-isvaop-keys.sh
```

### 2. Configure Hosts File

```bash
sudo nano /etc/hosts

# Add these lines:
127.0.0.2    lmi.iamlab.ibm.com
127.0.0.3    www.iamlab.ibm.com
```

### 3. Create Shared Directories

```bash
cd /root/ivia/verify-access-container-deployment/compose
./create-keyshares.sh
```

### 4. Choose Deployment Type

**Option A: Standard Deployment (Recommended for first-time users)**
```bash
cd /root/ivia/verify-access-container-deployment/compose/iamlab
```

**Option B: Snapshot Manager Deployment**
```bash
cd /root/ivia/verify-access-container-deployment/compose/snapmgr
```

### 5. Launch Environment

```bash
# Optional: Review configuration
cat .env
cat docker-compose.yaml

# Start containers
docker-compose up -d

# Monitor startup
docker-compose logs -f
```

## Verify Deployment

```bash
# Check container status (all should show "Up")
docker-compose ps

# Access LMI
# Open browser: https://127.0.0.2:9443 or https://lmi.iamlab.ibm.com:9443
# Login: admin / Passw0rd
```

## Common Commands

```bash
# View logs
docker-compose logs -f [container_name]

# Restart containers
docker-compose restart

# Stop containers
docker-compose stop

# Stop and remove (keeps data)
docker-compose down

# Stop and remove everything (including volumes)
docker-compose down -v

# Check resource usage
docker stats
```

## Troubleshooting Quick Fixes

### Containers won't start
```bash
docker-compose logs <container_name>
docker-compose restart
```

### Port conflicts
```bash
sudo lsof -i :9443
# Stop conflicting service or change ports in .env
```

### Certificate issues
```bash
rm -rf local/dockerkeys
./common/create-ldap-and-postgres-isvaop-keys.sh
./compose/create-keyshares.sh
cd compose/iamlab && docker-compose down -v && docker-compose up -d
```

## Default Credentials

| Service | Username | Password |
|---------|----------|----------|
| LMI Admin | admin | Passw0rd |
| LDAP Admin | cn=root | Passw0rd |
| PostgreSQL | postgres | Passw0rd |
| Snapshot Manager | snapmgr | Passw0rd |

## Access Points

| Service | URL | IP:Port |
|---------|-----|---------|
| LMI | https://lmi.iamlab.ibm.com:9443 | 127.0.0.2:9443 |
| WebSEAL | https://www.iamlab.ibm.com:9443 | 127.0.0.3:9443 |
| LDAPS | ldaps://lmi.iamlab.ibm.com:1636 | 127.0.0.2:1636 |

## Deployment Comparison

### Standard Deployment (iamlab)
- **Best for**: Development, testing, learning
- **Configuration**: Shared volume (`/var/shared`)
- **Components**: Full stack (8 containers)
- **Complexity**: Simple

### Snapshot Manager Deployment (snapmgr)
- **Best for**: Production-like environments
- **Configuration**: Centralized snapshot distribution
- **Components**: Includes snapshot manager
- **Complexity**: Moderate

## Next Steps After Deployment

1. **Accept License** - First login to LMI
2. **Configure cfgsvc user** - System → Account Management → Set password to `Passw0rd`
3. **Verify LDAP** - Secure Settings → LDAP → Test connection
4. **Verify Database** - Secure Settings → Database → Test connection
5. **Create WebSEAL instance** - Follow LMI wizard or use automated configuration

## Automated Configuration (Optional)

For automated setup using Python:

```bash
cd /root/ivia/verify-access-container-deployment/configuration
ln -s pki $HOME/dockershare/composekeys
pip install verify-access-autoconf
source env.properties
python -m verify_access_autoconf
```

## Backup and Restore

### Backup
```bash
cd /root/ivia/verify-access-container-deployment/compose
./ivia-backup-compose.sh
```

### Restore
```bash
# 1. Delete keystores
rm -rf /root/ivia/verify-access-container-deployment/local/dockerkeys

# 2. Restore keys
cd /root/ivia/verify-access-container-deployment/common
./restore-keys.sh <backup-file.tar>

# 3. Setup environment (steps 1-5 above)

# 4. Restore configuration
cd /root/ivia/verify-access-container-deployment/compose
./ivia-restore-compose.sh <backup-file.tar>
```

## Complete Cleanup

```bash
# Stop and remove everything
cd /root/ivia/verify-access-container-deployment/compose/iamlab
docker-compose down -v

# Remove shared directories
rm -rf $HOME/dockershare
rm -rf /root/ivia/verify-access-container-deployment/local/dockerkeys

# Remove images (optional)
docker images | grep ivia
docker rmi <image-id>
```

## Resources

- **Detailed Guide**: [`DOCKER_COMPOSE_DEPLOYMENT_GUIDE.md`](DOCKER_COMPOSE_DEPLOYMENT_GUIDE.md)
- **Project README**: [`README.md`](README.md)
- **IBM Documentation**: https://www.ibm.com/docs/en/sva/11.0.2
- **Docker Cookbook**: http://ibm.biz/Verify_Access_Docker_Cookbook
- **Community**: https://ibm.biz/iamcommunity

## Architecture Overview

```
┌─────────────────────────────────────────┐
│         Docker Compose Network          │
│                                         │
│  ┌──────────┐      ┌──────────┐       │
│  │iviaconfig│      │iviawrprp1│       │
│  │  (LMI)   │      │ (WebSEAL)│       │
│  └────┬─────┘      └────┬─────┘       │
│       │                 │              │
│  ┌────┴─────────────────┴────┐        │
│  │      iviaruntime          │        │
│  │    (AAC Runtime)          │        │
│  └────┬──────────────────────┘        │
│       │                               │
│  ┌────┴────┐    ┌──────────┐         │
│  │ iviadsc │    │iviadsc-  │         │
│  │  (DSC)  │    │ replica  │         │
│  └─────────┘    └──────────┘         │
│                                       │
│  ┌─────────┐    ┌──────────┐         │
│  │openldap │    │postgresql│         │
│  └─────────┘    └──────────┘         │
│                                       │
│  ┌─────────┐                          │
│  │ iviaop  │                          │
│  │ (OIDC)  │                          │
│  └─────────┘                          │
└─────────────────────────────────────────┘
```

## Version Information

- **IBM Verify Access**: 11.0.0.0
- **OpenLDAP**: 10.0.6.0
- **PostgreSQL**: 11.0.0.0
- **OIDC Provider**: 24.12

---

**⚠️ Security Warning**: Default passwords are `Passw0rd` - change these for production use!
