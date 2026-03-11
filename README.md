# THISJOWI Helm Chart

Umbrella chart para desplegar la plataforma **THISJOWI** en Kubernetes. Incluye los microservicios de la aplicación y toda la infraestructura necesaria.

## Servicios incluidos

### Microservicios
| Servicio | Puerto | Imagen |
|---|---|---|
| `auth-service` | 8080 | `thsjowi/auth` |
| `config-server` | 8888 | `thsjowi/config` |
| `password-manager` | 8084 | `thsjowi/password` |
| `otp-service` | 8085 | `thsjowi/otp` |
| `notes-service` | 8083 | `thsjowi/note` |
| `messages-service` | 8086 | `thsjowi/messages` |

### Infraestructura
| Componente | Chart | Versión |
|---|---|---|
| CockroachDB | `cockroachdb/cockroachdb` | 19.0.6 |
| Kafka | `bitnami/kafka` | 26.8.5 |
| Cassandra | `bitnami/cassandra` | 10.5.3 |
| Redis | `bitnami/redis` | 18.19.4 |

## Requisitos previos

- Kubernetes 1.21+
- Helm 3.x
- [Traefik](https://doc.traefik.io/traefik/getting-started/install-traefik/) como Ingress Controller
- [Linkerd](https://linkerd.io/2/getting-started/) (service mesh, opcional pero recomendado)

## Configuración

Antes de instalar, edita `values.yaml` y rellena todos los campos marcados con `[CONFIGURAR]`.

### 1. Ingress

```yaml
ingress:
  enabled: true
  host: "api.tudominio.com"   # Tu dominio real
  entrypoint: web             # web = HTTP | websecure = HTTPS
```

### 2. Secretos

Todos los campos vacíos deben rellenarse antes de la instalación:

```yaml
secrets:
  # Base de datos (CockroachDB)
  dbPort: "26257"
  dbUsername: "tu_usuario"
  dbPassword: "tu_contraseña"

  # Redis
  redisPort: "6379"
  redisPassword: "tu_contraseña_redis"

  # Kafka
  kafkaHost: "kafka"
  kafkaPort: "9092"

  # JWT (mínimo 32 caracteres)
  jwtSecret: "una_clave_secreta_muy_larga_y_segura"

  # Correo electrónico
  mailUsername: "usuario@ejemplo.com"
  mailPassword: "tu_contraseña_email"
  mailSenderEmail: "noreply@tudominio.com"
  mailSenderName: "THISJOWI"

  # OAuth Google (opcional)
  googleClientId: ""
  googleClientSecret: ""

  # OAuth GitHub (opcional)
  githubClientId: ""
  githubClientSecret: ""

  # Cassandra
  cassandraUsername: "cassandra"
  cassandraPassword: "tu_contraseña_cassandra"

  auth: "tu_token_de_autenticacion"
```

### 3. Versiones de imágenes

Puedes ajustar la versión (`tag`) de cada microservicio:

```yaml
auth-service:
  image:
    tag: "1.0.0"

config-server:
  image:
    tag: "1.0.0"

password-manager:
  image:
    tag: "1.0.0"

otp-service:
  image:
    tag: "1.0.0"

notes-service:
  image:
    tag: "1.0.1"

messages-service:
  image:
    tag: "1.0.9"
```

### 4. Configuración avanzada de messages-service

Si usas Cassandra o Kafka externos, configura sus hosts en el bloque de `messages-service`:

```yaml
messages-service:
  cassandra:
    host: "cassandra"      # Host de Cassandra
    port: "9042"
    datacenter: "DC1"
    keyspace: "messaging"
  kafka:
    host: "kafka"          # Host de Kafka
    port: "9092"
    groupId: "messages-service"
```

### 5. Habilitar/deshabilitar componentes

Cualquier servicio puede deshabilitarse individualmente:

```yaml
cockroachdb:
  enabled: false   # No despliega CockroachDB (p.ej. si usas una DB externa)
```

## Instalación

```bash
# 1. Descargar dependencias
helm dependency update

# 2. Instalar el chart
helm install thisjowi . -n thisjowi --create-namespace
```

## Actualización

Después de modificar `values.yaml`:

```bash
helm upgrade thisjowi . -n thisjowi
```

## Rutas expuestas

Una vez desplegado, la API estará disponible en el host configurado:

| Ruta | Servicio |
|---|---|
| `GET /v1/auth` | auth-service |
| `GET /v1/passwords` | password-manager |
| `GET /v1/notes` | notes-service |
| `GET /v1/otp` | otp-service |
| `GET /v1/messages` | messages-service |

## Operaciones útiles

```bash
# Ver estado de los pods
kubectl get pods -n thisjowi

# Ver logs de un servicio específico
kubectl logs -n thisjowi deployment/auth
kubectl logs -n thisjowi deployment/password
kubectl logs -n thisjowi deployment/notes
kubectl logs -n thisjowi deployment/otp
kubectl logs -n thisjowi deployment/messages

# Desinstalar
helm uninstall thisjowi -n thisjowi
```
