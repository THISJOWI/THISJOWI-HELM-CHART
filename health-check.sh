#!/bin/bash
# ===========================================================
# THISJOWI - Health Check & Validation Script
# ===========================================================
# Verifica que la instalación está funcionando correctamente
# Uso: ./health-check.sh [namespace]
# ===========================================================

NAMESPACE="${1:-thisjowi}"
TIMEOUT=300  # 5 minutos
INTERVAL=5   # Verificar cada 5 segundos

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funciones
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║         THISJOWI - HEALTH CHECK                       ║
║     Verificación de instalación y servicios           ║
╚═══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Verificar namespace
print_info "Verificando namespace: $NAMESPACE"
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
  print_error "Namespace '$NAMESPACE' no existe"
  exit 1
fi
print_success "Namespace encontrado"

# Verificar secrets
print_info "Verificando secretos..."
if kubectl get secret thisjowi-secrets -n "$NAMESPACE" &> /dev/null; then
  print_success "Secretos configurados"
else
  print_error "Secretos no encontrados"
  exit 1
fi

# Esperar a que los pods estén listos
print_info "Esperando a que los pods estén listos (máximo 5 minutos)..."
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
  READY_PODS=$(kubectl get pods -n "$NAMESPACE" --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
  TOTAL_PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
  
  echo -ne "\033[A\033[K"  # Limpiar línea anterior
  echo -ne "  Pods listos: $READY_PODS/$TOTAL_PODS\r"
  
  if [ $READY_PODS -gt 0 ] && [ $READY_PODS -eq $TOTAL_PODS ]; then
    print_success "Todos los pods están listos"
    break
  fi
  
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
  print_warning "Timeout esperando pods (continuando con verificación)"
fi

echo ""

# Verificar servicios
print_info "Verificando servicios..."
SERVICES=("config-server" "password-manager" "otp-service" "notes-service" "messages-service" "auth-service")

for service in "${SERVICES[@]}"; do
  if kubectl get service "$service" -n "$NAMESPACE" &> /dev/null; then
    print_success "Servicio $service encontrado"
  else
    print_warning "Servicio $service no encontrado (puede no estar habilitado)"
  fi
done

echo ""

# Verificar Ingress
print_info "Verificando Ingress..."
if kubectl get ingress thisjowi-ingress -n "$NAMESPACE" &> /dev/null; then
  INGRESS_HOST=$(kubectl get ingress thisjowi-ingress -n "$NAMESPACE" -o jsonpath='{.spec.rules[0].host}')
  INGRESS_IP=$(kubectl get ingress thisjowi-ingress -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pendiente")
  
  print_success "Ingress configurado"
  echo "  Host:       $INGRESS_HOST"
  echo "  IP/LoadBalancer: $INGRESS_IP"
else
  print_warning "Ingress no encontrado"
fi

echo ""

# Verificar salud de pods
print_info "Verificando salud de pods..."
echo ""

UNHEALTHY=0
kubectl get pods -n "$NAMESPACE" -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,READY:.status.conditions[?(@.type==\"Ready\")].status --no-headers | while read -r pod status ready; do
  if [ "$status" = "Running" ] && [ "$ready" = "True" ]; then
    print_success "Pod $pod está correcto"
  else
    print_warning "Pod $pod: Status=$status, Ready=$ready"
    UNHEALTHY=$((UNHEALTHY + 1))
  fi
done

echo ""

# Resumen de recursos
print_info "Resumen de recursos:"
echo ""
kubectl get pods -n "$NAMESPACE" -o wide

echo ""
echo "═══════════════════════════════════════════════════════"

# Verificación de conectividad
print_info "Verificando conectividad entre servicios..."
echo ""

# Intentar conectar a auth-service
if kubectl run -it --rm test-curl --image=curlimages/curl --restart=Never -n "$NAMESPACE" -- \
  curl -s http://auth:80/health &> /dev/null; then
  print_success "Conectividad OK"
else
  print_warning "No se pudo verificar conectividad (los servicios pueden no tener /health)"
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "✓ VERIFICACIÓN COMPLETADA"
echo "═══════════════════════════════════════════════════════"
echo ""

# Instrucciones finales
echo "Próximos pasos:"
echo ""
echo "1. Ver detalles de un pod:"
echo "   kubectl describe pod [pod-name] -n $NAMESPACE"
echo ""
echo "2. Ver logs de un servicio:"
echo "   kubectl logs [pod-name] -n $NAMESPACE"
echo ""
echo "3. Ejecutar un shell en un pod:"
echo "   kubectl exec -it [pod-name] -n $NAMESPACE -- /bin/bash"
echo ""
echo "4. Port-forward a un servicio:"
echo "   kubectl port-forward -n $NAMESPACE svc/auth 8080:80"
echo ""
