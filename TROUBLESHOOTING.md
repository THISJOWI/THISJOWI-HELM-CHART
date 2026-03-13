# THISJOWI - Troubleshooting Guide

## Errores Comunes y Soluciones

### Error: "no cached repo found" o "traefik-index.yaml not found"

**Error Completo:**
```
Error: INSTALLATION FAILED: no cached repo found. (try 'helm repo update'): 
open /Users/joel/Library/Caches/helm/repository/traefik-index.yaml: no such file or directory
```

**Causa:**
Este error ocurría porque el chart tenía dependencias externas (bases de datos, Kafka, etc.) que no estaban disponibles en tu sistema.

**Solución:**

✅ **Ya está resuelto en la versión actual**. El chart ha sido optimizado para ser verdaderamente "Plug & Play" sin dependencias externas.

Simplemente ejecuta:

```bash
helm install thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git -n thisjowi --create-namespace
```

---

## Otros Errores Comunes

### 1. "Error: release name already exists"

**Solución:**
El release ya existe. Elige otro nombre o desinstala el anterior:

```bash
# Desinstalar el release anterior
helm uninstall thisjowi -n thisjowi

# O usar otro nombre
helm install my-thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git -n thisjowi --create-namespace
```

---

### 2. "Error: create: failed to create containing directory"

**Solución:**
El namespace no existe. Helm debería crearlo con `--create-namespace`:

```bash
helm install thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi \
  --create-namespace  # Asegúrate de incluir esto
```

---

### 3. "Pods are in CrashLoopBackOff"

**Diagnóstico:**

```bash
# Ver el pod que falla
kubectl get pods -n thisjowi

# Ver qué está mal
kubectl describe pod [pod-name] -n thisjowi

# Ver los logs
kubectl logs -n thisjowi [pod-name]
```

**Causas Comunes:**

#### 3a. El pod no puede conectarse a la base de datos

Si usas una base de datos externa:

```bash
helm upgrade thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi \
  --set secrets.dbPassword="tu-contraseña-correcta"
```

#### 3b. Falta variables de entorno requeridas

Algunos servicios necesitan credenciales. Verifica que todos los secretos estén configurados:

```bash
kubectl get secret thisjowi-secrets -n thisjowi -o yaml
```

---

### 4. "ImagePullBackOff" o "ErrImagePull"

**Causa:** 
Las imágenes de Docker no están disponibles o no se puede acceder a ellas.

**Soluciones:**

a) Verificar que las imágenes existen:
```bash
docker pull thsjowi/auth:latest
docker pull thsjowi/password:latest
# ... etc
```

b) Si las imágenes están en un registry privado, crear un secret:
```bash
kubectl create secret docker-registry regcred \
  --docker-server=docker.io \
  --docker-username=tu-usuario \
  --docker-password=tu-password \
  -n thisjowi
```

c) Usar imágenes diferentes (tag específico):
```bash
helm upgrade thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi \
  --set auth-service.image.tag="v1.2.3"
```

---

### 5. "Pending" en PersistentVolumeClaim

**Causa:**
No hay StorageClass disponible o no hay espacio en disco.

**Soluciones:**

a) Ver StorageClasses disponibles:
```bash
kubectl get storageclass
```

b) Especificar un StorageClass:
```bash
helm upgrade thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi \
  --set persistence.storageClass="fast-ssd"
```

c) Ver PVCs pendientes:
```bash
kubectl get pvc -n thisjowi

# Ver detalles
kubectl describe pvc [pvc-name] -n thisjowi
```

---

### 6. "Ingress not responding" o "External IP is \<pending\>"

**Causa:**
El Ingress Controller (Traefik) no está instalado o bien configurado.

**Soluciones:**

a) Verificar que Traefik está instalado:
```bash
kubectl get pods -n kube-system | grep traefik

# Si no está, instalarlo:
helm repo add traefik https://traefik.github.io/charts
helm install traefik traefik/traefik -n kube-system
```

b) Obtener la IP/LoadBalancer:
```bash
kubectl get ingress -n thisjowi

# Si está en "pending", espera a que se asigne
kubectl get ingress -n thisjowi -w
```

c) Para desarrollo local, usar port-forward:
```bash
kubectl port-forward -n thisjowi svc/auth 8080:80
# Accede a http://localhost:8080
```

---

### 7. Servicios no pueden comunicarse entre sí

**Diagnóstico:**

```bash
# Verificar connectivity
kubectl run -it --rm test --image=curlimages/curl --restart=Never -n thisjowi -- \
  curl http://auth:80/health
```

**Soluciones:**

a) Verificar que los servicios existen:
```bash
kubectl get svc -n thisjowi
```

b) Si tienes NetworkPolicies habilitadas, asegúrate de que permite tráfico:
```bash
kubectl get networkpolicies -n thisjowi

# Desabilitar temporalmente para diagnosticar
kubectl delete networkpolicies -n thisjowi --all
```

c) Verificar logs de conectividad:
```bash
kubectl logs -n thisjowi -f [pod-name]
```

---

### 8. "Secret 'thisjowi-secrets' not found"

**Causa:**
No se creó el secret correctamente durante la instalación.

**Solución:**

Verificar si existe:
```bash
kubectl get secret -n thisjowi
```

Si no existe, crear manualmente:
```bash
kubectl create secret generic thisjowi-secrets \
  --from-literal=DB_PASSWORD="tu-password" \
  --from-literal=JWT_SECRET="tu-jwt" \
  -n thisjowi
```

---

### 9. "Invalid JWT token" o "Authentication failed"

**Causa:**
El JWT_SECRET no está configurado correctamente.

**Solución:**

Generar un nuevo JWT secret válido:
```bash
# Generar uno seguro
SECURE_JWT=$(openssl rand -base64 48)

helm upgrade thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi \
  --set secrets.jwtSecret="$SECURE_JWT"
```

---

### 10. "Database connection refused"

**Causa:**
No se puede conectar a la base de datos externa.

**Diagnóstico:**

```bash
# Desde un pod
kubectl exec -it [pod-name] -n thisjowi -- /bin/bash

# Dentro del pod
telnet [db-host] 26257  # Para CockroachDB
psql -h [db-host] -U root  # Si es PostgreSQL compatible
```

**Soluciones:**

a) Verificar credenciales:
```bash
helm get values thisjowi -n thisjowi | grep secrets
```

b) Actualizar conexión:
```bash
helm upgrade thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi \
  --set secrets.dbUsername="correcto-user" \
  --set secrets.dbPassword="correcto-password"
```

c) Verificar firewall/networking:
```bash
# Desde el pod
kubectl -n thisjowi run -it --rm debug --image=busybox --restart=Never -- \
  nc -zv [db-host] 26257
```

---

## 📊 Debugging útiles

### Ver el estado completo de la instalación

```bash
kubectl describe all -n thisjowi
```

### Ver todos los eventos

```bash
kubectl get events -n thisjowi --sort-by='.lastTimestamp'
```

### Exportar configuración actual

```bash
helm get values thisjowi -n thisjowi > current-values.yaml
```

### Hacer dry-run de actualización

```bash
helm upgrade thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi \
  --dry-run \
  --debug
```

### Verificar templates que se generarían

```bash
helm template thisjowi https://github.com/THISJOWI/THISJOWI-HELM-CHART.git \
  -n thisjowi > generated-manifests.yaml
```

---

## 🚨 Emergency: Rollback a versión anterior

Si algo salió mal:

```bash
# Ver historial
helm history thisjowi -n thisjowi

# Rollback a la revisión anterior
helm rollback thisjowi -n thisjowi

# O a una revisión específica
helm rollback thisjowi 1 -n thisjowi
```

---

## 📞 Obtener ayuda

Si el problema persiste:

1. Recopila información:
```bash
kubectl describe all -n thisjowi > debug-info.txt
kubectl logs -n thisjowi --all-containers=true > logs.txt
helm get values thisjowi -n thisjowi > values.txt
```

2. Abre un issue en [GitHub](https://github.com/THISJOWI/THISJOWI-HELM-CHART/issues)

3. Incluye:
   - Versión de Kubernetes: `kubectl version`
   - Versión de Helm: `helm version`
   - Output de los comandos anteriores
   - Los comandos exactos que ejecutaste

---

## ❓ FAQ

**P: ¿Dónde van los datos de la base de datos?**
R: Si usas una BD externa, los datos están en ese servidor. Si despliegas infraestructura en el cluster, están en los PersistentVolumes. Ver [Infrastructure Components](INFRASTRUCTURE.md).

**P: ¿Puedo cambiar las contraseñas después de instalar?**
R: Sí, con `helm upgrade` puedes cambiar secrets:
```bash
helm upgrade thisjowi ... --set secrets.dbPassword="nuevo-password"
```

**P: ¿Cómo backupeo los datos?**
R: Depende de dónde estén tus datos. Si están en PVCs, puedes crear snapshots del volumen.

**P: ¿Puedo escalar horizontalmente?**
R: Sí, aumenta las replicas:
```bash
helm upgrade thisjowi ... --set auth-service.replicaCount=5
```
