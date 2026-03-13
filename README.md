# THISJOWI Helm Chart

> 🚀 **Plug & Play installation** - Secure, automatic, zero-configuration deployment

[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.20+-blue)](https://kubernetes.io)
[![Helm](https://img.shields.io/badge/Helm-3.0+-green)](https://helm.sh)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

THISJOWI is a complete microservices platform with automatic secret generation, security policies, and zero-configuration deployment.

## 📦 What's Included

- **auth-service** - Authentication & Authorization (Port 8080)
- **password-manager** - Secure password management (Port 8084)
- **otp-service** - One-Time Password service (Port 8085)
- **notes-service** - Notes management (Port 8083)
- **messages-service** - Messaging with Cassandra & Kafka (Port 8086)
- **config-server** - Central configuration service (Port 8888)

## ⚡ Quick Install

### 30-Second Installation

```bash
# From GitHub (Recommended)
helm install thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi \
  --create-namespace
```

That's it! All secrets are auto-generated. The application is ready.

**Note**: This installs only THISJOWI microservices. Database, Redis, Kafka, and Cassandra are configured as external services by default. If you want to deploy them in the cluster, see [Infrastructure Components](INFRASTRUCTURE.md).

### With Custom Domain

```bash
helm install thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi \
  --create-namespace \
  --set ingress.host=api.example.com
```

### Production Setup

```bash
helm install thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi \
  --create-namespace \
  --set ingress.host=api.example.com \
  --set environment=production \
  --set auth-service.replicaCount=3 \
  --set messages-service.replicaCount=3
```

## ✨ Features

- ✅ **Zero Configuration** - Everything auto-configured
- ✅ **Secure by Default** - Auto-generated 32+ character secrets
- ✅ **Auto IP Detection** - Detects cluster IP automatically
- ✅ **Health Checks** - Readiness and liveness probes on all services
- ✅ **RBAC Enabled** - Role-based access control
- ✅ **Network Policies** - Optional network isolation
- ✅ **Resource Limits** - CPU and memory constraints set
- ✅ **Non-root** - Runs as non-root user by default
- ✅ **Multi-environment** - development, staging, production

## 📋 Requirements

- Kubernetes 1.20+
- Helm 3.0+
- kubectl configured

```bash
# Verify requirements
kubectl cluster-info
helm version
```

## 🔐 Security

### Auto-Generated Secrets
These are automatically created with 32+ random characters:
- Database password
- Redis password
- JWT secret (critical)
- Cassandra password
- Auth token

### Security Features
- RBAC enabled by default
- Pod security context (non-root user 1000)
- Network policies available
- Service accounts with minimal permissions
- Secrets stored in Kubernetes Secrets

## 📊 Installation Options

### Option 1: From GitHub (Recommended)

```bash
# Basic
helm install thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi --create-namespace

# With parameters
helm install thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi --create-namespace \
  --set ingress.host=api.example.com \
  --set environment=production
```

### Option 2: From Local Clone

```bash
git clone https://github.com/THISJOWI/THISJOWI-HELM-CHART.git
cd THISJOWI-HELM-CHART

helm install thisjowi ./helm -n thisjowi --create-namespace
```

### Option 3: Using Installation Script

```bash
git clone https://github.com/THISJOWI/THISJOWI-HELM-CHART.git
cd THISJOWI-HELM-CHART/helm

chmod +x install.sh
./install.sh --domain api.example.com --environment production
```

## 🔧 Common Commands

### View Installation Status

```bash
# Check pods
kubectl get pods -n thisjowi

# Check services
kubectl get svc -n thisjowi

# Check ingress
kubectl get ingress -n thisjowi

# View detailed status
kubectl describe pods -n thisjowi
```

### View Logs

```bash
# View auth service logs
kubectl logs -n thisjowi -f deployment/auth

# View specific pod logs
kubectl logs -n thisjowi [pod-name]
```

### Port Forwarding (Development)

```bash
# Forward auth service
kubectl port-forward -n thisjowi svc/auth 8080:80

# Forward all services
kubectl port-forward -n thisjowi svc/auth 8080:80 &
kubectl port-forward -n thisjowi svc/password 8084:80 &
kubectl port-forward -n thisjowi svc/otp 8085:80 &
```

### Get Access Information

```bash
# Get application URL
kubectl get ingress -n thisjowi -o jsonpath='{.items[0].spec.rules[0].host}'

# Get secrets
kubectl get secret -n thisjowi

# View secret values (use carefully!)
kubectl get secret thisjowi-secrets -n thisjowi -o yaml
```

## 📈 Upgrade

```bash
# Upgrade to latest
helm upgrade thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git -n thisjowi

# Upgrade with new values
helm upgrade thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi \
  --set environment=production
```

## 🗑️ Uninstall

```bash
# Remove the release
helm uninstall thisjowi -n thisjowi

# Remove the namespace
kubectl delete namespace thisjowi
```

## ⚙️ Configuration

### Common Parameters

```bash
# Set custom domain
--set ingress.host=api.example.com

# Set environment (development|staging|production)
--set environment=production

# Set custom database password
--set secrets.dbPassword="your-secure-password"

# Set custom JWT secret
--set secrets.jwtSecret="your-jwt-token"

# Increase replicas for high availability
--set auth-service.replicaCount=3
--set messages-service.replicaCount=3

# Enable TLS/HTTPS
--set ingress.tls.enabled=true

# Enable network policies
--set security.networkPolicy.enabled=true

# Use specific image versions
--set auth-service.image.tag="v1.2.3"
```

### Full Parameter List

See [values.yaml](values.yaml) for complete configuration options.

## 🐛 Troubleshooting

### Pods not starting

```bash
# Check pod status
kubectl describe pod [pod-name] -n thisjowi

# View logs
kubectl logs [pod-name] -n thisjowi

# Check events
kubectl get events -n thisjowi --sort-by='.lastTimestamp'
```

### Ingress not responding

```bash
# Check ingress status
kubectl get ingress -n thisjowi -o yaml

# Verify Traefik is installed
kubectl get deployment -n kube-system | grep traefik
```

### Services not communicating

```bash
# Test connectivity
kubectl run -it --rm test --image=curlimages/curl --restart=Never -n thisjowi -- \
  curl http://auth:80/health

# Check network policies
kubectl get networkpolicies -n thisjowi
```

### Secrets not found

```bash
# Verify secrets exist
kubectl get secrets -n thisjowi

# Check secret contents
kubectl describe secret thisjowi-secrets -n thisjowi
```

## 📚 Documentation

- [Installation Guide](INSTALL.md) - Detailed installation instructions
- [Infrastructure Components](INFRASTRUCTURE.md) - How to deploy databases, caches, and message brokers
- [Troubleshooting Guide](TROUBLESHOOTING.md) - Common issues and solutions
- [values.yaml](values.yaml) - All configuration parameters
- [Contributing](../CONTRIBUTING.md) - How to contribute
- [Security Policy](../SECURITY.md) - Security guidelines

## 🎯 Use Cases

### Development

```bash
helm install thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi --create-namespace
```

### Staging

```bash
helm install thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi --create-namespace \
  --set ingress.host=staging-api.example.com \
  --set environment=staging
```

### Production

```bash
helm install thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi --create-namespace \
  --set ingress.host=api.example.com \
  --set environment=production \
  --set auth-service.replicaCount=3 \
  --set messages-service.replicaCount=3 \
  --set secrets.dbPassword="$(openssl rand -base64 32)" \
  --set secrets.jwtSecret="$(openssl rand -base64 48)" \
  --set security.rbac.enabled=true \
  --set security.networkPolicy.enabled=true
```

## 📞 Support

- 📖 [Documentation](INSTALL.md)
- 🐛 [Report Issues](https://github.com/THISJOWI/THISJOWI-HELM-CHART/issues)
- 💬 [Discussions](https://github.com/THISJOWI/THISJOWI-HELM-CHART/discussions)

## 📄 License

This project is licensed under the MIT License - see [LICENSE](../LICENSE) file for details.

## 🙏 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

---

**Made with ❤️ by the THISJOWI Team**

[GitHub](https://github.com/THISJOWI) | [Twitter](https://twitter.com/THISJOWI) | [Website](https://thisjowi.com)
