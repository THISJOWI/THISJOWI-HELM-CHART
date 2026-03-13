#!/bin/bash
# ===========================================================
# THISJOWI - Instalador Automático PLUG & PLAY
# ===========================================================
# Uso: ./install.sh [opciones]
# Ejemplo: ./install.sh --domain mi-dominio.com --environment production
# ===========================================================

set -e

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

# Valores por defecto
NAMESPACE="thisjowi"
RELEASE_NAME="thisjowi"
DOMAIN=""
ENVIRONMENT="development"
DRY_RUN=false
CHART_PATH="./helm"

# Función para imprimir mensajes
print_info() {
  echo -e "${BLUE}ℹ ${1}${NC}"
}

print_success() {
  echo -e "${GREEN}✓ ${1}${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠ ${1}${NC}"
}

print_error() {
  echo -e "${RED}✗ ${1}${NC}"
}

# Función de ayuda
show_help() {
  cat << EOF
THISJOWI - Instalador Automático Plug & Play

Uso: ./install.sh [opciones]

Opciones:
  -h, --help                Muestra esta ayuda
  -d, --domain DOMINIO      Tu dominio (ej: miapp.com)
  -e, --environment ENV     Entorno: development|staging|production (default: development)
  -n, --namespace NS        Namespace de Kubernetes (default: thisjowi)
  -r, --release NAME        Nombre del release Helm (default: thisjowi)
  --dry-run                 Simular instalación sin hacer cambios
  --chart-path PATH         Ruta del chart Helm (default: ./helm)

Ejemplos:
  # Instalación rápida (plug & play)
  ./install.sh

  # Con dominio personalizado
  ./install.sh --domain myapp.example.com

  # Producción
  ./install.sh --domain api.example.com --environment production

  # Simular instalación
  ./install.sh --dry-run

EOF
  exit 0
}

# Parsear argumentos
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      ;;
    -d|--domain)
      DOMAIN="$2"
      shift 2
      ;;
    -e|--environment)
      ENVIRONMENT="$2"
      shift 2
      ;;
    -n|--namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    -r|--release)
      RELEASE_NAME="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --chart-path)
      CHART_PATH="$2"
      shift 2
      ;;
    *)
      print_error "Opción desconocida: $1"
      show_help
      ;;
  esac
done

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║         THISJOWI - INSTALADOR PLUG & PLAY             ║
║     Instalación automática y segura de THISJOWI       ║
╚═══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Validar kubectl
print_info "Validando kubectl..."
if ! command -v kubectl &> /dev/null; then
  print_error "kubectl no está instalado"
  exit 1
fi
print_success "kubectl encontrado"

# Validar helm
print_info "Validando Helm..."
if ! command -v helm &> /dev/null; then
  print_error "Helm no está instalado"
  exit 1
fi
print_success "Helm encontrado"

# Validar conexión a cluster
print_info "Validando conexión a Kubernetes cluster..."
if ! kubectl cluster-info &> /dev/null; then
  print_error "No hay conexión a un cluster de Kubernetes"
  exit 1
fi
YOUR_CLUSTER=$(kubectl config current-context)
print_success "Conectado a: $YOUR_CLUSTER"

# Crear namespace
print_info "Verificando namespace..."
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
  print_warning "Namespace '$NAMESPACE' no existe, creando..."
  kubectl create namespace "$NAMESPACE"
  print_success "Namespace '$NAMESPACE' creado"
else
  print_success "Namespace '$NAMESPACE' ya existe"
fi

# Detectar IP si no se proporciona dominio
if [ -z "$DOMAIN" ]; then
  print_info "Detectando IP del cluster..."
  
  # Intentar obtener IP externa
  NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}' 2>/dev/null || echo "")
  
  # Si no hay IP externa, usar interna
  if [ -z "$NODE_IP" ]; then
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "")
  fi
  
  if [ -n "$NODE_IP" ]; then
    DOMAIN="${NODE_IP}.nip.io"
    print_success "IP detectada: $NODE_IP"
    print_success "Dominio auto-generado: $DOMAIN"
  else
    DOMAIN="localhost"
    print_warning "No se pudo detectar IP, usando: $DOMAIN"
  fi
fi

# Mostrar configuración
echo ""
print_info "Configuración de instalación:"
echo "  Cluster:        $YOUR_CLUSTER"
echo "  Namespace:      $NAMESPACE"
echo "  Release:        $RELEASE_NAME"
echo "  Dominio:        $DOMAIN"
echo "  Entorno:        $ENVIRONMENT"
echo "  Chart:          $CHART_PATH"
echo ""

# Validar chart
if [ ! -f "$CHART_PATH/Chart.yaml" ]; then
  print_error "Chart no encontrado en: $CHART_PATH/Chart.yaml"
  exit 1
fi

# Construir comando helm
HELM_CMD="helm upgrade --install $RELEASE_NAME $CHART_PATH"
HELM_CMD="$HELM_CMD --namespace $NAMESPACE"
HELM_CMD="$HELM_CMD --set ingress.host=$DOMAIN"
HELM_CMD="$HELM_CMD --set environment=$ENVIRONMENT"
HELM_CMD="$HELM_CMD --create-namespace"
HELM_CMD="$HELM_CMD --wait"

if [ "$DRY_RUN" = true ]; then
  HELM_CMD="$HELM_CMD --dry-run --debug"
fi

# Instalar/Actualizar
echo ""
if [ "$DRY_RUN" = true ]; then
  print_warning "Modo DRY-RUN activado (sin hacer cambios)"
  echo ""
fi

print_info "Instalando THISJOWI..."
echo ""

if eval "$HELM_CMD"; then
  print_success "THISJOWI instalado correctamente"
  
  if [ "$DRY_RUN" = false ]; then
    echo ""
    print_info "Esperando a que los pods se inicien..."
    sleep 5
    
    # Mostrar estado
    echo ""
    print_info "Estado de los pods:"
    kubectl get pods -n "$NAMESPACE" -w &
    WATCH_PID=$!
    sleep 10
    kill $WATCH_PID 2>/dev/null || true
    
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "✓ INSTALACIÓN COMPLETADA"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    echo "Acceso a la aplicación:"
    if [[ "$DOMAIN" == "localhost" ]]; then
      echo "  http://localhost"
    else
      echo "  http://$DOMAIN"
    fi
    echo ""
    echo "Comandos útiles:"
    echo "  Ver estado:      kubectl get all -n $NAMESPACE"
    echo "  Ver logs:        kubectl logs -n $NAMESPACE -f [pod-name]"
    echo "  Port forward:    kubectl port-forward -n $NAMESPACE svc/auth 8080:80"
    echo "  Actualizar:      helm upgrade $RELEASE_NAME $CHART_PATH -n $NAMESPACE"
    echo "  Desinstalar:     helm uninstall $RELEASE_NAME -n $NAMESPACE"
    echo ""
  fi
else
  print_error "Error durante la instalación"
  exit 1
fi
