# IBM Verify Access Docker Compose Deployment Guide

This guide provides step-by-step instructions for deploying IBM Verify Access v11.0.0.0 using Docker Compose.

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Architecture](#architecture)
4. [Deployment Options](#deployment-options)
5. [Step-by-Step Deployment](#step-by-step-deployment)
6. [Post-Deployment Configuration](#post-deployment-configuration)
7. [Troubleshooting](#troubleshooting)
8. [Backup and Restore](#backup-and-restore)

---

## Overview

IBM Verify Access (IVIA) provides secure access management capabilities. This Docker Compose deployment includes:

- **Configuration Container** (`iviaconfig`) - Management interface (LMI)
- **Web Reverse Proxy** (`iviawrprp1`) - Handles web traffic
- **Runtime Container** (`iviaruntime`) - Advanced Access Control runtime
- **DSC Containers** (`iviadsc`, `iviadsc-replica`) - Distributed Session Cache
- **OpenLDAP** - Directory service
- **PostgreSQL** - Database service
- **OIDC Provider** (`iviaop`) - OpenID Connect provider (optional)

---

## Prerequisites

### System Requirements
- **Operating System**: Linux (tested on Ubuntu/RHEL/CentOS)
- **Docker**: Version 20.10 or later
- **Docker Compose**: Version 1.29 or later (or Docker Compose V2)
- **Memory**: Minimum 8GB RAM recommended
- **Disk Space**: At least 20GB free space
- **Network**: Access to IBM Container Registry (icr.io)

### Required Tools
```bash
# Verify Docker installation
docker --version

# Verify Docker Compose installation
docker-compose --version
# OR for Docker Compose V2
docker compose version

# Verify OpenSSL (for certificate generation)
openssl version
```

### Access Requirements
- Access to IBM Container Registry: `icr.io/ivia/`
- Valid IBM entitlement key (if required for your version)
- Write access to `$HOME` and `/tmp` directories

---

## Architecture

### Network Architecture
```
┌─────────────────────────────────────────────────────────┐
│                  Docker Compose Network                  │
│                   (ivia-compose-net)                     │
│                                                          │
│  ┌──────────────┐    ┌──────────────┐                  │
│  │  iviaconfig  │    │  iviawrprp1  │                  │
│  │   (LMI)      │    │   (WebSEAL)  │                  │
│  │  Port: 9443  │    │  Port: 9443  │                  │
│  └──────┬───────┘    └──────┬───────┘                  │
│         │                   │                           │
│  ┌──────┴───────────────────┴───────┐                  │
│  │         iviaruntime              │                  │
│  │    (AAC Runtime)                 │                  │
│  └──────┬───────────────────────────┘                  │
│         │                                               │
│  ┌──────┴───────┐    ┌──────────────┐                  │
│  │   iviadsc    │    │iviadsc-replica│                 │
│  │   (DSC-1)    │    │   (DSC-2)    │                  │
│  └──────────────┘    └──────────────┘                  │
│                                                          │
│  ┌──────────────┐    ┌──────────────┐                  │
│  │   openldap   │    │  postgresql  │                  │
│  │  Port: 636   │    │  Port: 5432  │                  │
│  └──────────────┘    └──────────────┘                  │
│                                                          │
│  ┌──────────────┐                                       │
│  │    iviaop    │                                       │
│  │ (OIDC Provider)                                      │
│  └──────────────┘                                       │
└─────────────────────────────────────────────────────────┘

External Access:
- LMI: https://127.0.0.2:9443 (lmi.iamlab.ibm.com)
- WebSEAL: https://127.0.0.3:9443 (www.iamlab.ibm.com)
- LDAP: ldaps://127.0.0.2:1636
```

### Volume Mounts
- **iviaconfig**: Shared configuration volume
- **libldap, ldapslapd, libsecauthority**: OpenLDAP data
- **pgdata**: PostgreSQL data
- **$HOME/dockershare/composekeys**: SSL certificates
- **$HOME/dockershare/isvaop-config**: OIDC Provider configuration

---

## Deployment Options

### Option 1: Standard Deployment (iamlab)
**Location**: `compose/iamlab/`

**Features**:
- Full IBM Verify Access stack
- Shared volume configuration
- All containers share `/var/shared` volume
- Suitable for development and testing

**Components**:
- Configuration container
- Web Reverse Proxy
- Runtime container
- 2x DSC containers
- OpenLDAP
- PostgreSQL
- OIDC Provider

### Option 2: Snapshot Manager Deployment (snapmgr)
**Location**: `compose/snapmgr/`

**Features**:
- Centralized snapshot management
- Snapshot Manager container for configuration distribution
- Worker containers pull config from snapshot manager
- Better for production-like environments

**Components**:
- Configuration container
- Snapshot Manager container
- Web Reverse Proxy
- Runtime container
- DSC container
- OpenLDAP
- PostgreSQL

**Key Difference**: Uses `CONFIG_SERVICE_URL` to point workers to snapshot manager instead of shared volumes.

---

## Step-by-Step Deployment

### Step 1: Verify Prerequisites

```bash
# Check Docker
docker --version
docker ps

# Check Docker Compose
docker-compose --version

# Check available disk space
df -h $HOME

# Check OpenSSL
openssl version
```

### Step 2: Create SSL/TLS Keystores

This step creates self-signed certificates for OpenLDAP, PostgreSQL, and ISVAOP components.

```bash
# Navigate to the project root
cd /root/ivia/verify-access-container-deployment

# Run the keystore creation script
./common/create-ldap-and-postgres-isvaop-keys.sh
```

**What this creates**:
- `local/dockerkeys/openldap/` - LDAP certificates (ldap.key, ldap.crt, ca.crt, dhparam.pem)
- `local/dockerkeys/postgresql/` - PostgreSQL certificates (postgres.key, postgres.crt, server.pem)
- `local/dockerkeys/isvaop/` - OIDC Provider certificates (isvaop_key.pem, isvaop.pem)

**Expected Output**:
```
Creating LDAP certificate files
Creating LDAP dhparam.pem
Creating postgres certificate files
Creating ISVAOP certificate files
```

### Step 3: Configure Network Access

Add hostname mappings to `/etc/hosts`:

```bash
# Edit /etc/hosts (requires sudo)
sudo nano /etc/hosts

# Add these lines:
127.0.0.2    lmi.iamlab.ibm.com
127.0.0.3    www.iamlab.ibm.com
```

**Note**: If you want to use different IP addresses, you must:
1. Update `common/env-config.sh` (MY_LMI_IP, MY_WEB1_IP, MY_WEB2_IP)
2. Run `compose/update-env-file.sh` to update the `.env` file

### Step 4: Create Docker Compose Shared Directories

```bash
# Navigate to compose directory
cd /root/ivia/verify-access-container-deployment/compose

# Run the keyshare creation script
./create-keyshares.sh
```

**What this does**:
- Creates `$HOME/dockershare/composekeys/` directory
- Copies all keystores from `local/dockerkeys/` to the shared location
- Creates `$HOME/dockershare/isvaop-config/` directory
- Copies OIDC Provider configuration files

**Expected Output**:
```
Creating key shares at /root/dockershare/composekeys
Done.
Creating isvaop config shares at /root/dockershare/isvaop-config
Done.
```

### Step 5: Choose and Configure Deployment

#### For Standard Deployment (iamlab):

```bash
# Navigate to iamlab directory
cd /root/ivia/verify-access-container-deployment/compose/iamlab

# Review the .env file
cat .env
```

**Default `.env` configuration**:
```env
TIMEZONE=Australia/Brisbane
ADMIN_PASSWORD=Passw0rd
CONTAINER_BASE=icr.io/ivia/ivia
ISVA_VERSION=11.0.0.0
LDAP_VERSION=11.0.0.0
DB_VERSION=11.0.0.0
LMI_IP=127.0.0.2
WEB1_IP=127.0.0.3
WEB2_IP=127.0.0.4
IVIAOP_VERSION=24.12
```

**Customization Options**:
- `TIMEZONE`: Set to your timezone (e.g., `Asia/Tokyo`, `America/New_York`)
- `ADMIN_PASSWORD`: Change from default `Passw0rd` (recommended for production)
- `ISVA_VERSION`: Container version (default: 11.0.0.0)
- IP addresses: Already configured from env-config.sh

#### For Snapshot Manager Deployment (snapmgr):

```bash
# Navigate to snapmgr directory
cd /root/ivia/verify-access-container-deployment/compose/snapmgr

# Review and edit .env file
nano .env
```

**Additional configuration**:
- `SNAPMGR_PW`: Password for snapshot manager (default: `Passw0rd`)

### Step 6: Review Docker Compose Configuration

```bash
# View the docker-compose.yaml file
cat docker-compose.yaml

# Validate the configuration
docker-compose config
```

**Key configuration points**:
- All passwords default to `Passw0rd`
- OpenLDAP domain: `ibm.com`
- PostgreSQL database: `ivia`
- Shared volumes for data persistence

### Step 7: Pull Container Images

```bash
# Pull all required images (optional but recommended)
docker-compose pull
```

**Images that will be pulled**:
- `icr.io/ivia/ivia-config:11.0.0.0`
- `icr.io/ivia/ivia-wrp:11.0.0.0`
- `icr.io/ivia/ivia-runtime:11.0.0.0`
- `icr.io/ivia/ivia-dsc:11.0.0.0`
- `icr.io/isva/verify-access-openldap:10.0.6.0`
- `icr.io/ivia/ivia-postgresql:11.0.0.0`
- `icr.io/ivia/ivia-oidc-provider:24.12`

### Step 8: Launch the Environment

```bash
# Start all containers in detached mode
docker-compose up -d
```

**Expected Output**:
```
Creating network "ivia-compose-net" with the default driver
Creating volume "iamlab_iviaconfig" with default driver
Creating volume "iamlab_libldap" with default driver
Creating volume "iamlab_ldapslapd" with default driver
Creating volume "iamlab_libsecauthority" with default driver
Creating volume "iamlab_pgdata" with default driver
Creating iamlab_openldap_1    ... done
Creating iamlab_postgresql_1  ... done
Creating iamlab_iviaconfig_1  ... done
Creating iamlab_iviaop_1      ... done
Creating iamlab_iviawrprp1_1  ... done
Creating iamlab_iviaruntime_1 ... done
Creating iamlab_iviadsc_1     ... done
Creating iamlab_iviadsc-replica_1 ... done
```

### Step 9: Verify Container Status

```bash
# Check all containers are running
docker-compose ps

# View logs for all containers
docker-compose logs

# View logs for specific container
docker-compose logs iviaconfig

# Follow logs in real-time
docker-compose logs -f
```

**Healthy Status**:
All containers should show `Up` status. Initial startup may take 2-5 minutes.

```
NAME                    STATUS
iamlab_iviaconfig_1     Up 2 minutes
iamlab_iviawrprp1_1     Up 2 minutes
iamlab_iviaruntime_1    Up 2 minutes
iamlab_iviadsc_1        Up 2 minutes
iamlab_iviadsc-replica_1 Up 2 minutes
iamlab_openldap_1       Up 2 minutes
iamlab_postgresql_1     Up 2 minutes
iamlab_iviaop_1         Up 2 minutes
```

---

## Post-Deployment Configuration

### Access the LMI (Local Management Interface)

1. **Open your browser** and navigate to:
   ```
   https://127.0.0.2:9443
   OR
   https://lmi.iamlab.ibm.com:9443
   ```

2. **Accept the self-signed certificate warning**

3. **Login credentials**:
   - Username: `admin`
   - Password: `Passw0rd` (or your custom password from .env)

### Initial Configuration Steps

1. **Accept License Agreement**
   - First login will prompt for license acceptance

2. **Configure cfgsvc User Password** (for Kubernetes/worker containers)
   - Navigate to: **System → Account Management**
   - Find user: `cfgsvc`
   - Set password to: `Passw0rd` (must match `configreader` secret)

3. **Verify LDAP Connection**
   - Navigate to: **Secure Settings → LDAP**
   - Test connection to `openldap:636`

4. **Verify Database Connection**
   - Navigate to: **Secure Settings → Database**
   - Test connection to `postgresql:5432`

### Access the Web Reverse Proxy

Once configured, access the reverse proxy at:
```
https://127.0.0.3:9443
OR
https://www.iamlab.ibm.com:9443
```

---

## Troubleshooting

### Container Won't Start

```bash
# Check container logs
docker-compose logs <container_name>

# Check container status
docker-compose ps

# Restart specific container
docker-compose restart <container_name>

# Restart all containers
docker-compose restart
```

### Port Already in Use

```bash
# Check what's using the port
sudo lsof -i :9443
sudo netstat -tulpn | grep 9443

# Stop conflicting service or change port in .env file
```

### Certificate Issues

```bash
# Recreate certificates
rm -rf local/dockerkeys
./common/create-ldap-and-postgres-isvaop-keys.sh
./compose/create-keyshares.sh

# Restart containers
cd compose/iamlab
docker-compose down -v
docker-compose up -d
```

### Volume Permission Issues

```bash
# Check volume permissions
ls -la $HOME/dockershare/composekeys

# Fix permissions if needed
chmod -R 755 $HOME/dockershare
```

### Network Issues

```bash
# Verify /etc/hosts entries
cat /etc/hosts | grep iamlab

# Test DNS resolution
ping lmi.iamlab.ibm.com
ping www.iamlab.ibm.com

# Check Docker network
docker network ls
docker network inspect ivia-compose-net
```

### View Container Resource Usage

```bash
# Check resource usage
docker stats

# Check disk usage
docker system df
```

---

## Backup and Restore

### Create Backup

```bash
# Navigate to compose directory
cd /root/ivia/verify-access-container-deployment/compose

# Run backup script
./ivia-backup-compose.sh
```

**Backup includes**:
- Keystores from `local/dockerkeys`
- OpenLDAP directory content
- PostgreSQL database content
- Configuration snapshot from config container

**Backup location**: Current directory (timestamped tar file)

### Restore from Backup

```bash
# 1. Delete existing keystores
rm -rf /root/ivia/verify-access-container-deployment/local/dockerkeys

# 2. Restore keystores
cd /root/ivia/verify-access-container-deployment/common
./restore-keys.sh <backup-tar-file>

# 3. Setup environment (follow steps 4-8 above)

# 4. Restore configuration
cd /root/ivia/verify-access-container-deployment/compose
./ivia-restore-compose.sh <backup-tar-file>
```

---

## Cleanup

### Stop and Remove Containers

```bash
# Stop all containers
docker-compose stop

# Stop and remove containers (keeps volumes)
docker-compose down

# Stop and remove containers AND volumes (complete cleanup)
docker-compose down -v
```

### Remove Shared Directories

```bash
# Remove Docker share directory
rm -rf $HOME/dockershare

# Remove local keystores
rm -rf /root/ivia/verify-access-container-deployment/local/dockerkeys
```

### Remove Docker Images

```bash
# List IVIA images
docker images | grep ivia

# Remove specific image
docker rmi icr.io/ivia/ivia-config:11.0.0.0

# Remove all unused images
docker image prune -a
```

---

## Additional Resources

### Official Documentation
- IBM Verify Access Documentation: https://www.ibm.com/docs/en/sva/11.0.2
- Docker Compose Documentation: https://docs.docker.com/compose/
- Docker Cookbook: http://ibm.biz/Verify_Access_Docker_Cookbook

### Community Support
- IBM Security Community: https://ibm.biz/iamcommunity
- Security Learning Academy: https://www.securitylearningacademy.com/

### Useful Commands

```bash
# View all containers (including stopped)
docker-compose ps -a

# Execute command in running container
docker-compose exec iviaconfig bash

# View container resource limits
docker-compose config

# Rebuild containers after config changes
docker-compose up -d --build

# Scale DSC containers
docker-compose up -d --scale iviadsc=3
```

---

## Security Considerations

### Production Deployment Checklist

- [ ] Change all default passwords (`Passw0rd`)
- [ ] Use proper SSL/TLS certificates (not self-signed)
- [ ] Restrict network access (don't expose all ports publicly)
- [ ] Enable firewall rules
- [ ] Regular backup schedule
- [ ] Monitor container logs
- [ ] Keep containers updated
- [ ] Use secrets management (Docker secrets or external vault)
- [ ] Implement proper access controls
- [ ] Regular security audits

### Password Locations to Update

1. `.env` file: `ADMIN_PASSWORD`, `SNAPMGR_PW`
2. `docker-compose.yaml`: 
   - `LDAP_ADMIN_PASSWORD`
   - `LDAP_CONFIG_PASSWORD`
   - `POSTGRES_PASSWORD`
3. LMI: `cfgsvc` user password

---

## Version Information

- **Guide Version**: 1.0
- **IBM Verify Access Version**: 11.0.0.0
- **Tested with Docker**: 20.10+
- **Tested with Docker Compose**: 1.29+ / V2
- **Last Updated**: 2026-02-09

---

## Quick Reference

### Default Credentials
- **LMI Admin**: admin / Passw0rd
- **LDAP Admin**: cn=root / Passw0rd
- **PostgreSQL**: postgres / Passw0rd
- **Snapshot Manager**: snapmgr / Passw0rd

### Default Ports
- **LMI**: 9443 (on 127.0.0.2)
- **WebSEAL**: 9443 (on 127.0.0.3)
- **LDAPS**: 1636 (on 127.0.0.2)

### Key Directories
- **Project Root**: `/root/ivia/verify-access-container-deployment`
- **Keystores**: `local/dockerkeys/`
- **Docker Share**: `$HOME/dockershare/`
- **Compose Configs**: `compose/iamlab/` or `compose/snapmgr/`
