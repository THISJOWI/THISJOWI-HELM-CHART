# THISJOWI - Infrastructure Components

> Guía para desplegar componentes de infraestructura opcionales: CockroachDB, Kafka, Cassandra, Redis

## ℹ️ Importante

**THISJOWI se instala sin infraestructura por defecto.** Puedes:

1. **Usar servicios externos** - Base de datos, caché, message broker en servidores externos _(Recomendado para producción)_
2. **Desplegar internamente** - Instalar infraestructura en el mismo cluster _(Útil para desarrollo/testing)_

## 🚀 Quick Start sin Infraestructura

Si tienes servicios externos, instala solo THISJOWI:

```bash
helm install thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi \
  --create-namespace \
  --set secrets.dbPassword="tu-contraseña" \
  # ... otros parámetros
```

## 📦 Instalar Infraestructura en el Cluster

### Prerequisitos

```bash
# Crear namespace
kubectl create namespace thisjowi

# Configurar repositorios de Helm
./setup-repos.sh
```

### Option 1: Instalación Manual Paso a Paso

#### 1. CockroachDB (Base de datos)

```bash
helm install cockroachdb cockroachdb/cockroachdb \
  -n thisjowi \
  --set statefulset.replicas=3 \
  --set tls.enabled=false \
  --set persistence.enabled=true \
  --set persistence.size=10Gi
```

Obtener la connectionstring:

```bash
# Port-forward
kubectl port-forward -n thisjowi svc/cockroachdb 26257:26257

# Connection string
postgresql://root@localhost:26257/defaultdb?sslmode=disable
```

#### 2. Redis (Caché)

```bash
helm install redis bitnami/redis \
  -n thisjowi \
  --set architecture=standalone \
  --set auth.enabled=false \
  --set persistence.enabled=true \
  --set persistence.size=5Gi
```

Obtener conexión:

```bash
# Port-forward
kubectl port-forward -n thisjowi svc/redis-master 6379:6379

# Connection
redis://localhost:6379/0
```

#### 3. Cassandra (Almacén de mensajes)

```bash
helm install cassandra bitnami/cassandra \
  -n thisjowi \
  --set replicaCount=1 \
  --set persistence.enabled=true \
  --set persistence.size=10Gi \
  --set auth.enabled=false
```

Obtener conexión:

```bash
# Port-forward
kubectl port-forward -n thisjowi svc/cassandra 9042:9042

# Connection
cassandra://localhost:9042
```

#### 4. Kafka (Message Broker)

```bash
helm install kafka bitnami/kafka \
  -n thisjowi \
  --set replicaCount=1 \
  --set persistence.enabled=true \
  --set auth.enabled=false
```

Obtener conexión:

```bash
# Port-forward
kubectl port-forward -n thisjowi svc/kafka 9092:9092

# Connection
kafka://localhost:9092
```

### Option 2: Instalación Automática (Script)

```bash
#!/bin/bash
# infrastructure-setup.sh

NAMESPACE="thisjowi"

# Crear namespace
kubectl create namespace $NAMESPACE

# Setup repos
./setup-repos.sh

# CockroachDB
helm install cockroachdb cockroachdb/cockroachdb -n $NAMESPACE \
  --set statefulset.replicas=3 \
  --set persistence.enabled=true

# Redis
helm install redis bitnami/redis -n $NAMESPACE \
  --set architecture=standalone \
  --set persistence.enabled=true

# Cassandra
helm install cassandra bitnami/cassandra -n $NAMESPACE \
  --set replicaCount=1 \
  --set persistence.enabled=true

# Kafka
helm install kafka bitnami/kafka -n $NAMESPACE \
  --set replicaCount=1 \
  --set persistence.enabled=true

echo "✓ Infraestructura instalada"
```

## 🔗 Conectar THISJOWI a la Infraestructura

Una vez instalada la infraestructura, configura THISJOWI para usarla:

```bash
helm install thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi \
  --create-namespace \
  --set secrets.dbPassword="tu-password-seguro" \
  --set secrets.cassandraPassword="cassandra-password" \
  --set secrets.jwtSecret="$(openssl rand -base64 48)" \
  --set secrets.redisPassword="redis-password" \
  --set secrets.kafkaHost="kafka" \
  --set secrets.cassandraHost="cassandra" \
  --set secrets.dbUsername="root" \
  --set messages-service.cassandra.host="cassandra" \
  --set messages-service.kafka.host="kafka"
```

## ☁️ Usar Servicios Externos (Recomendado para Producción)

Si tienes infraestructura fuera del cluster:

```bash
helm install thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi \
  --create-namespace \
  --set secrets.dbPassword="external-db-password" \
  --set secrets.dbUsername="external-user" \
  --set messages-service.cassandra.host="cassandra.example.com" \
  --set messages-service.kafka.host="kafka.example.com" \
  --set secrets.cassandraHost="cassandra.example.com" \
  --set secrets.kafkaHost="kafka.example.com"
```

## 📊 Estructura de Conectividad

```
┌─────────────────────────────────────┐
│      THISJOWI Microservicios       │
│  (auth, password, otp, notes, etc) │
└──────────────┬──────────────────────┘
               │
       ┌───────┼───────┬───────────┬────────────┐
       │       │       │           │            │
  ┌────▼──┐ ┌──▼───┐ ┌─▼─────┐ ┌──▼───────┐ ┌─▼──────┐
  │  CDB  │ │Redis │ │Kafka  │ │Cassandra │ │Config  │
  │ (DB)  │ │Cache │ │  MQ   │ │ Messages │ │Server  │
  └───────┘ └──────┘ └───────┘ └──────────┘ └────────┘
  26257    6379     9092      9042         8888
```

## 🔍 Monitoreo de Infraestructura

### Ver estado de los servicios

```bash
# Pods de infraestructura
kubectl get pods -n thisjowi -l app.kubernetes.io/instance=cockroachdb
kubectl get pods -n thisjowi -l app.kubernetes.io/instance=redis
kubectl get pods -n thisjowi -l app.kubernetes.io/instance=kafka
kubectl get pods -n thisjowi -l app.kubernetes.io/instance=cassandra

# Servicios disponibles
kubectl get svc -n thisjowi
```

### Acceder a interfaces web

```bash
# CockroachDB Admin Panel (port 8080)
kubectl port-forward -n thisjowi svc/cockroachdb-public 8080:8080
# http://localhost:8080

# Kafdrop para Kafka (si se instala)
kubectl port-forward -n thisjowi svc/kafdrop 9000:9000
# http://localhost:9000
```

## 🗑️ Desinstalar Componentes

```bash
# Remover CockroachDB
helm uninstall cockroachdb -n thisjowi

# Remover Redis
helm uninstall redis -n thisjowi

# Remover Kafka
helm uninstall kafka -n thisjowi

# Remover Cassandra
helm uninstall cassandra -n thisjowi

# Si quieres purgar completamente (CUIDADO: elimina datos)
helm uninstall cockroachdb -n thisjowi --no-hooks
kubectl delete pvc -n thisjowi -l app.kubernetes.io/name=cockroachdb
```

## 📝 Configuración Avanzada

### CockroachDB HA (3 replicas)

```bash
helm install cockroachdb cockroachdb/cockroachdb \
  -n thisjowi \
  --set statefulset.replicas=3 \
  --set persistence.enabled=true \
  --set persistence.size=50Gi \
  --set resources.requests.memory=4Gi \
  --set resources.requests.cpu=2 \
  --set storage.persistentVolume.size=50Gi
```

### Redis Sentinel (Alta Disponibilidad)

```bash
helm install redis bitnami/redis \
  -n thisjowi \
  --set architecture=replication \
  --set replica.replicaCount=2 \
  --set sentinel.enabled=true \
  --set sentinel.quorum=2
```

### Kafka Cluster (3 replicas)

```bash
helm install kafka bitnami/kafka \
  -n thisjowi \
  --set replicaCount=3 \
  --set persistence.enabled=true \
  --set persistence.size=20Gi \
  --set resources.requests.memory=2Gi \
  --set resources.requests.cpu=1
```

## 🆘 Troubleshooting

### Pod de infraestructura no inicia

```bash
# Ver descripción
kubectl describe pod [pod-name] -n thisjowi

# Ver logs
kubectl logs [pod-name] -n thisjowi

# Ver eventos
kubectl get events -n thisjowi --sort-by='.lastTimestamp'
```

### No hay espacio en disco

```bash
# Ver PVCs
kubectl get pvc -n thisjowi

# Aumentar tamaño
kubectl patch pvc [pvc-name] -n thisjowi -p \
  '{"spec":{"resources":{"requests":{"storage":"50Gi"}}}}'
```

### Conectividad entre servicios

```bash
# Ejecutar un test pod
kubectl run -it --rm test --image=curlimages/curl --restart=Never -n thisjowi -- \
  curl http://cockroachdb:26257

# O desde un contenedor existente
kubectl exec -it [pod-name] -n thisjowi -- /bin/bash
```

## 📚 Referencias

- [CockroachDB Helm Chart](https://www.cockroachlabs.com/docs/v21.1/kubernetes-overview)
- [Bitnami Helm Charts](https://github.com/bitnami/charts)
- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [Cassandra Documentation](https://cassandra.apache.org/doc/latest/)

## 💡 Mejores Prácticas

1. **Desarrollo**: Instala todo en el mismo cluster
2. **Staging**: Usa persistencia, 2 replicas para infraestructura
3. **Producción**: Usa servicios externos gestionados (Cloud) o clusters separados para infraestructura

4. **Backups**: Configura snapshots de PVCs regularmente
5. **Monitoreo**: Instala Prometheus + Grafana
6. **Logging**: Configura ELK o Loki para centralizar logs
