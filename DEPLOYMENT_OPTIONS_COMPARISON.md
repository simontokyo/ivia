# IBM Verify Access - Deployment Options Comparison

This document compares the different deployment options available for IBM Verify Access, helping you choose the right approach for your needs.

## Available Deployment Methods

1. **Native Docker** (`docker/`)
2. **Docker Compose - Standard** (`compose/iamlab/`)
3. **Docker Compose - Snapshot Manager** (`compose/snapmgr/`)
4. **Kubernetes** (`kubernetes/`)
5. **Helm** (`helm/`)
6. **OpenShift** (`openshift/`)

---

## Docker Compose Deployments (Focus)

### Standard Deployment (iamlab)

**Location**: `compose/iamlab/`

#### Architecture
```
┌─────────────────────────────────────────────┐
│         Shared Volume Architecture          │
│                                             │
│  All containers mount: /var/shared          │
│                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │iviaconfig│  │iviawrprp1│  │iviaruntime│ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘ │
│       │             │              │        │
│       └─────────────┴──────────────┘        │
│                     │                       │
│              ┌──────▼──────┐                │
│              │ iviaconfig  │                │
│              │   volume    │                │
│              └─────────────┘                │
└─────────────────────────────────────────────┘
```

#### Characteristics
- **Configuration Method**: Shared volume (`/var/shared`)
- **Containers**: 8 total
  - iviaconfig (LMI)
  - iviawrprp1 (WebSEAL)
  - iviaruntime (AAC Runtime)
  - iviadsc (DSC primary)
  - iviadsc-replica (DSC replica)
  - openldap
  - postgresql
  - iviaop (OIDC Provider)

#### Pros
- ✅ Simple setup and configuration
- ✅ All containers share configuration directly
- ✅ Fast configuration propagation
- ✅ Easy to understand for beginners
- ✅ Good for development and testing
- ✅ Minimal network overhead

#### Cons
- ❌ Not ideal for production scaling
- ❌ Tight coupling between containers
- ❌ Volume sharing can cause permission issues
- ❌ Less flexible for distributed deployments

#### Best For
- Development environments
- Testing and QA
- Learning IBM Verify Access
- Single-host deployments
- Quick prototyping

#### Configuration Files
- `docker-compose.yaml` - Container definitions
- `.env` - Environment variables
- Shared volume: `iviaconfig:/var/shared`

---

### Snapshot Manager Deployment (snapmgr)

**Location**: `compose/snapmgr/`

#### Architecture
```
┌─────────────────────────────────────────────┐
│    Centralized Snapshot Distribution        │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │      iviasnapmgr (Port 9443)         │  │
│  │   Centralized Configuration Store    │  │
│  └──────────────┬───────────────────────┘  │
│                 │                           │
│     ┌───────────┼───────────┐              │
│     │           │           │              │
│  ┌──▼──────┐ ┌─▼────────┐ ┌▼─────────┐    │
│  │iviaconfig│ │iviawrprp1│ │iviaruntime│   │
│  │  (LMI)   │ │ (WebSEAL)│ │  (AAC)   │    │
│  └──────────┘ └──────────┘ └──────────┘    │
│                                             │
│  Workers pull config from snapshot manager  │
└─────────────────────────────────────────────┘
```

#### Characteristics
- **Configuration Method**: Centralized snapshot manager
- **Containers**: 6 total
  - iviaconfig (LMI)
  - iviasnapmgr (Snapshot Manager)
  - iviawrprp1 (WebSEAL)
  - iviaruntime (AAC Runtime)
  - iviadsc (DSC)
  - openldap
  - postgresql

#### Configuration Variables
```yaml
CONFIG_SERVICE_URL=https://iviasnapmgr:9443
CONFIG_SERVICE_USER_NAME=snapmgr
CONFIG_SERVICE_USER_PWD=Passw0rd
```

#### Pros
- ✅ Production-ready architecture
- ✅ Better for scaling
- ✅ Centralized configuration management
- ✅ Workers are loosely coupled
- ✅ Easier to add/remove worker containers
- ✅ Better snapshot versioning
- ✅ Simulates production deployment

#### Cons
- ❌ More complex setup
- ❌ Additional container overhead
- ❌ Network dependency for config access
- ❌ Requires snapshot manager credentials

#### Best For
- Production-like environments
- Multi-instance deployments
- Testing scaling scenarios
- Configuration management testing
- Environments requiring snapshot versioning

#### Configuration Files
- `docker-compose.yaml` - Container definitions
- `.env` - Environment variables (includes `SNAPMGR_PW`)
- No shared volumes for configuration

---

## Side-by-Side Comparison

| Feature | Standard (iamlab) | Snapshot Manager (snapmgr) |
|---------|-------------------|----------------------------|
| **Complexity** | Low | Medium |
| **Setup Time** | 5 minutes | 10 minutes |
| **Container Count** | 8 | 6 |
| **Config Method** | Shared volume | HTTP API |
| **Scaling** | Limited | Good |
| **Production Ready** | No | Yes |
| **Learning Curve** | Easy | Moderate |
| **Network Overhead** | Minimal | Moderate |
| **Config Propagation** | Instant | On-demand |
| **Snapshot Versioning** | Manual | Built-in |
| **Worker Independence** | Low | High |
| **Best Use Case** | Dev/Test | Staging/Prod |

---

## Other Deployment Methods

### Native Docker

**Location**: `docker/`

#### Characteristics
- Manual container creation using `docker run`
- No orchestration
- Requires IP address configuration
- Uses `docker-setup.sh` script

#### When to Use
- Learning Docker basics
- Maximum control over container configuration
- Custom networking requirements
- Single-host deployments without orchestration

---

### Kubernetes

**Location**: `kubernetes/`

#### Characteristics
- Full Kubernetes orchestration
- Multiple YAML files for different cloud providers
- Requires `kubectl` CLI
- Supports Minikube, IBM Cloud, Google Cloud

#### When to Use
- Production Kubernetes clusters
- Cloud-native deployments
- Need for auto-scaling
- High availability requirements
- Multi-node clusters

---

### Helm

**Location**: `helm/`

#### Characteristics
- Kubernetes package manager
- Templated YAML files
- Version management
- Easy upgrades and rollbacks
- Chart version: v1.3.0+

#### When to Use
- Kubernetes deployments with templating
- Need for easy upgrades
- Multiple environment deployments
- Configuration management at scale
- Standardized deployments

---

### OpenShift

**Location**: `openshift/`

#### Characteristics
- Red Hat OpenShift platform
- Templates for OpenShift 3.x and 4.x
- Built-in security constraints
- Route-based ingress
- Operator support available

#### When to Use
- OpenShift environments
- Enterprise deployments
- Need for OpenShift-specific features
- Operator-based management
- Red Hat ecosystem

---

## Decision Matrix

### Choose **Docker Compose (Standard)** if:
- ✓ You're new to IBM Verify Access
- ✓ You need a quick development environment
- ✓ You're running on a single host
- ✓ You want simple configuration
- ✓ You're learning the product

### Choose **Docker Compose (Snapshot Manager)** if:
- ✓ You need a production-like environment
- ✓ You want to test scaling scenarios
- ✓ You need centralized configuration management
- ✓ You're preparing for production deployment
- ✓ You need snapshot versioning

### Choose **Native Docker** if:
- ✓ You need maximum control
- ✓ You're learning Docker fundamentals
- ✓ You have custom networking requirements
- ✓ You don't need orchestration

### Choose **Kubernetes** if:
- ✓ You have a Kubernetes cluster
- ✓ You need production-grade orchestration
- ✓ You need auto-scaling
- ✓ You need high availability
- ✓ You're deploying to cloud

### Choose **Helm** if:
- ✓ You're using Kubernetes
- ✓ You need templating and versioning
- ✓ You manage multiple environments
- ✓ You need easy upgrades
- ✓ You want standardized deployments

### Choose **OpenShift** if:
- ✓ You're using Red Hat OpenShift
- ✓ You need enterprise features
- ✓ You want operator-based management
- ✓ You need OpenShift security features

---

## Migration Path

### Development → Production

```
1. Start: Docker Compose (Standard)
   ↓
2. Test: Docker Compose (Snapshot Manager)
   ↓
3. Stage: Kubernetes or Helm
   ↓
4. Production: Kubernetes/Helm/OpenShift
```

### Recommended Learning Path

```
1. Docker Compose (Standard) - Learn basics
   ↓
2. Docker Compose (Snapshot Manager) - Understand architecture
   ↓
3. Kubernetes/Helm - Production deployment
```

---

## Configuration Differences

### Standard Deployment Environment Variables
```env
TIMEZONE=Australia/Brisbane
ADMIN_PASSWORD=Passw0rd
CONTAINER_BASE=icr.io/ivia/ivia
ISVA_VERSION=11.0.2.0
LDAP_VERSION=11.0.2.0
DB_VERSION=11.0.2.0
LMI_IP=127.0.0.2
WEB1_IP=127.0.0.3
WEB2_IP=127.0.0.4
IVIAOP_VERSION=24.12
```

### Snapshot Manager Additional Variables
```env
SNAPMGR_PW=Passw0rd
```

### Container Environment Differences

**Standard (Shared Volume)**:
```yaml
volumes:
  - iviaconfig:/var/shared:rw,z
```

**Snapshot Manager (API)**:
```yaml
environment:
  - CONFIG_SERVICE_URL=https://iviasnapmgr:9443
  - CONFIG_SERVICE_USER_NAME=snapmgr
  - CONFIG_SERVICE_USER_PWD=${SNAPMGR_PW}
```

---

## Performance Considerations

### Standard Deployment
- **Startup Time**: ~2-3 minutes
- **Memory Usage**: ~6-8 GB
- **Disk I/O**: High (shared volume)
- **Network**: Minimal

### Snapshot Manager Deployment
- **Startup Time**: ~3-4 minutes
- **Memory Usage**: ~5-7 GB
- **Disk I/O**: Low
- **Network**: Moderate (HTTP API calls)

---

## Troubleshooting by Deployment Type

### Standard Deployment Issues
- Volume permission problems
- SELinux context issues
- Shared volume corruption
- Container startup order

### Snapshot Manager Issues
- Network connectivity to snapshot manager
- Authentication failures
- Snapshot download timeouts
- Certificate validation errors

---

## Summary Recommendation

**For your first deployment**, we recommend:

1. **Start with Docker Compose (Standard)** - `compose/iamlab/`
   - Easiest to understand
   - Fastest to deploy
   - Best for learning

2. **Then try Snapshot Manager** - `compose/snapmgr/`
   - Understand production architecture
   - Learn snapshot management
   - Test scaling scenarios

3. **Finally move to Kubernetes/Helm** - `kubernetes/` or `helm/`
   - Production deployment
   - Enterprise features
   - High availability

---

## Quick Start Commands

### Standard Deployment
```bash
cd /root/ivia/verify-access-container-deployment
./common/create-ldap-and-postgres-isvaop-keys.sh
cd compose
./create-keyshares.sh
cd iamlab
docker-compose up -d
```

### Snapshot Manager Deployment
```bash
cd /root/ivia/verify-access-container-deployment
./common/create-ldap-and-postgres-isvaop-keys.sh
cd compose
./create-keyshares.sh
cd snapmgr
docker-compose up -d
```

---

## Additional Resources

- **Detailed Guide**: [`DOCKER_COMPOSE_DEPLOYMENT_GUIDE.md`](DOCKER_COMPOSE_DEPLOYMENT_GUIDE.md)
- **Quick Start**: [`QUICK_START.md`](QUICK_START.md)
- **Project README**: [`README.md`](README.md)
- **IBM Documentation**: https://www.ibm.com/docs/en/sva/11.0.2
