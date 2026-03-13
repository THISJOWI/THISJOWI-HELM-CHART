# THISJOWI - Installation Guide

**Instalación automática, segura y sin configuración requerida**

## 🚀 Quick Start (30 segundos)

### ⭐ Opción 1: Desde GitHub (Recomendado - Una línea)

```bash
# Instalación simple desde el repositorio de THISJOWI
helm install thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi \
  --create-namespace
```

¡Eso es todo! El chart se descarga automáticamente de GitHub y se instala. Todos los secretos se generan automáticamente.

**⚠️ Nota Importante**: 
- Esto instala solo los **microservicios de THISJOWI** (auth, password, otp, notes, messages)
- La **infraestructura es opcional**: CockroachDB, Redis, Kafka, Cassandra se configuran como servicios externos
- Si quieres desplegar infraestructura en el cluster, ver [Infrastructure Components](INFRASTRUCTURE.md)

#### Con dominio personalizado

```bash
helm install thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi \
  --create-namespace \
  --set ingress.host=mi-app.com
```

#### Entorno de producción con alta disponibilidad

```bash
helm install thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi \
  --create-namespace \
  --set ingress.host=api.example.com \
  --set environment=production \
  --set auth-service.replicaCount=3 \
  --set messages-service.replicaCount=3
```

---

### Opción 2: Script de instalación (Manual mejorado)

```bash
# Clonar el repositorio
git clone https://github.com/THISJOWI/THISJOWI-HELM-CHART.git
cd THISJOWI-HELM-CHART/helm

# Hacer ejecutable
chmod +x install.sh

# Instalar con auto-detección de IP
./install.sh

# O con dominio personalizado
./install.sh --domain mi-app.com --environment production
```

### Opción 3: Helm directo (Local)

## ✨ Características

- ✅ **Plug & Play**: Sin configuración requerida, todo se auto-genera
- ✅ **Secrets Seguros**: Contraseñas y tokens se generan automáticamente (32+ caracteres)
- ✅ **Auto-detección de IP**: Obtiene la IP del cluster automáticamente
- ✅ **Health Checks**: Readiness y liveness probes en todos los servicios
- ✅ **RBAC**: Control de acceso basado en roles
- ✅ **Limites de Recursos**: CPU y memoria bien configuradas
- ✅ **Múltiples Entornos**: development, staging, production

## 📋 Requisitos

- Kubernetes 1.20+
- Helm 3.0+
- kubectl configurado

```bash
# Verificar requierimientos
kubectl cluster-info
helm version
```

## 🔧 Comandos de Instalación

### Instalación Rápida (Defecto)
```bash
./helm/install.sh
```
- Namespace: `thisjowi`
- Dominio: Auto-detectado (ej: `192.168.1.100.nip.io`)
- Entorno: `development`

### Con Dominio Personalizado
```bash
./helm/install.sh --domain api.example.com
```

### Entorno de Producción
```bash
./helm/install.sh \
  --domain api.example.com \
  --environment production
```

### Modo Dry-Run (Ver qué se instalaría)
```bash
./helm/install.sh --dry-run
```

### Destino a Namespace Específico
```bash
./helm/install.sh --namespace mi-namespace --release my-release
```

## 📊 Estructura de Instalación

```
Namespace: thisjowi
├── config-server        (Puerto 8888)
├── password-manager     (Puerto 8084)
├── otp-service          (Puerto 8085)
├── notes-service        (Puerto 8083)
├── messages-service     (Puerto 8086) + Cassandra + Kafka
├── auth-service         (Puerto 8080)
├── Secrets (Auto-generados)
└── Ingress (Traefik)
```

## 🔐 Seguridad

### Secretos Auto-generados
Todos estos se generan **automáticamente**:
- ✅ Database Password (32 caracteres aleatorios)
- ✅ Redis Password (32 caracteres aleatorios)
- ✅ JWT Secret (32+ caracteres, crítico)
- ✅ Cassandra Password (32 caracteres aleatorios)
- ✅ Auth Token (32 caracteres aleatorios)

### Personalizados (Opcional)
Si quieres usar secretos específicos:

```bash
./helm/install.sh \
  --domain api.example.com \
  --set secrets.dbPassword="tu-password-seguro" \
  --set secrets.jwtSecret="tu-jwt-token-largo"
```

### Context de Seguridad
- `runAsNonRoot: true`
- `runAsUser: 1000`
- `fsGroup: 1000`

### RBAC Habilitado
- ServiceAccounts por servicio
- Roles con permisos mínimos
- RoleBindings configuradas

## 📱 Acceso a la Aplicación

Después de instalar, accede a:

```bash
# Obtener IP/Dominio
kubectl get ingress -n thisjowi

# Puerto-forward para desarrollo
kubectl port-forward -n thisjowi svc/auth 8080:80

# Ver en browser
http://localhost:8080
```

## 📊 Verificar Instalación

```bash
# Ver todos los pods
kubectl get pods -n thisjowi

# Ver estado detallado
kubectl describe pods -n thisjowi

# Ver servicios
kubectl get svc -n thisjowi

# Ver ingress
kubectl get ingress -n thisjowi

# Ver secrets (sin valores sensibles)
kubectl get secrets -n thisjowi

# Ver logs
kubectl logs -n thisjowi -f [pod-name]
```

## 🔄 Actualizar Installation

```bash
# Actualizar a Latest
helm upgrade thisjowi ./helm -n thisjowi

# Cambiar valores
helm upgrade thisjowi ./helm \
  -n thisjowi \
  --set environment=production

# Ver cambios antes de aplicar
helm upgrade thisjowi ./helm -n thisjowi --dry-run
```

## 🗑️ Desinstalar

```bash
# Remover completamente
helm uninstall thisjowi -n thisjowi

# Remover namespace
kubectl delete namespace thisjowi
```

## 🔧 Personalización Avanzada

### Cambiar Versiones de Imágenes

```bash
helm install thisjowi ./helm -n thisjowi --create-namespace \
  --set config-server.image.tag="v1.2.3" \
  --set auth-service.image.tag="v2.0.0"
```

### Aumentar Replicas (para carga)

```bash
helm upgrade thisjowi ./helm -n thisjowi \
  --set auth-service.replicaCount=3 \
  --set messages-service.replicaCount=5
```

### Habilitar HTTPS/TLS

```bash
helm install thisjowi ./helm -n thisjowi --create-namespace \
  --set ingress.tls.enabled=true \
  --set ingress.entrypoint=websecure
```

### Habilitar NetworkPolicies

```bash
helm install thisjowi ./helm -n thisjowi --create-namespace \
  --set security.networkPolicy.enabled=true
```

## 📦 Infrastructure (Opcional)

Si quieres instalar las dependencias dentro del cluster:

```bash
helm install thisjowi ./helm -n thisjowi --create-namespace \
  --set infrastructure.cockroachdb.enabled=true \
  --set infrastructure.redis.enabled=true \
  --set infrastructure.kafka.enabled=true \
  --set infrastructure.cassandra.enabled=true
```

## 🐛 Troubleshooting

### Pod no inicia
```bash
kubectl describe pod [pod-name] -n thisjowi
kubectl logs [pod-name] -n thisjowi
```

### Ingress no responde
```bash
kubectl get ingress -n thisjowi -o yaml
# Verificar que Traefik está instalado
kubectl get pods -n kube-system | grep traefik
```

### Errores de secretos
```bash
# Verificar secretos
kubectl get secret thisjowi-secrets -n thisjowi -o yaml
```

## 💡 Tips

1. **Desarrollo Local**: Usa `install.sh` sin parámetros
2. **Staging**: Usa `--environment staging`
3. **Producción**: 
   - Usa `--environment production`
   - Personaliza `secrets.dbPassword` y `secrets.jwtSecret`
   - Habilita TLS: `--set ingress.tls.enabled=true`
   - Aumenta replicas: `--set [service].replicaCount=3`

4. **High Availability**: 
   ```bash
   helm upgrade thisjowi ./helm -n thisjowi \
     --set auth-service.replicaCount=3 \
     --set messages-service.replicaCount=3
   ```

## 📞 Soporte

Para problemas o preguntas:
- Revisa [CONTRIBUTING.md](../CONTRIBUTING.md)
- Abre un issue en el repositorio
- Contacta al equipo DevOps

## 📚 Documentación Adicional

- [values.yaml](./values.yaml) - Todos los parámetros disponibles
- [Chart.yaml](./Chart.yaml) - Información del chart
- [../SECURITY.md](../SECURITY.md) - Políticas de seguridad
