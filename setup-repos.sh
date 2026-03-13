#!/bin/bash
# ===========================================================
# THISJOWI - Setup Helm Repositories Script
# ===========================================================
# Configura los repositorios de Helm necesarios para la
# instalación de componentes de infraestructura opcionales
# ===========================================================

set -e

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }

echo -e "${BLUE}"
cat << "EOF"
╔════════════════════════════════════════════════════════╗
║    THISJOWI - Configurar Repositorios de Helm          ║
║  Para componentes de infraestructura opcionales        ║
╚════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

print_info "Configurando repositorios de Helm..."
echo ""

# CockroachDB
print_info "Agregando repositorio CockroachDB..."
helm repo add cockroachdb https://charts.cockroachdb.com && \
  print_success "CockroachDB agregado" || \
  print_error "Error agregando CockroachDB"

# Bitnami (para Kafka, Cassandra, Redis)
print_info "Agregando repositorio Bitnami..."
helm repo add bitnami https://charts.bitnami.com/bitnami && \
  print_success "Bitnami agregado" || \
  print_error "Error agregando Bitnami"

echo ""
print_info "Actualizando índices locales..."
helm repo update && print_success "Índices actualizados" || \
  print_error "Error actualizando índices"

echo ""
echo "════════════════════════════════════════════════════"
echo "✓ REPOSITORIOS CONFIGURADOS"
echo "════════════════════════════════════════════════════"
echo ""
echo "Ahora puedes instalar componentes de infraestructura:"
echo ""
echo "1. CockroachDB:"
echo "   helm install cockroachdb cockroachdb/cockroachdb -n thisjowi"
echo ""
echo "2. Kafka:"
echo "   helm install kafka bitnami/kafka -n thisjowi"
echo ""
echo "3. Cassandra:"
echo "   helm install cassandra bitnami/cassandra -n thisjowi"
echo ""
echo "4. Redis:"
echo "   helm install redis bitnami/redis -n thisjowi"
echo ""
echo "O ver: INFRASTRUCTURE.md para instalación completa"
echo ""
