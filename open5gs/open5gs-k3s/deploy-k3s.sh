#!/bin/bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Verify kubectl works
if ! kubectl get nodes &>/dev/null; then
    print_error "kubectl not configured properly"
    exit 1
fi

print_info "Starting Open5GS deployment..."

# Step 1: Foundation - Create namespace first
print_info "Creating namespace..."
kubectl apply -f 00-foundation/namespace.yaml

# Wait a moment for namespace to be fully ready
sleep 2

# Verify namespace exists
if ! kubectl get namespace open5gs &>/dev/null; then
    print_error "Failed to create namespace"
    exit 1
fi
print_success "Namespace created"

# Apply remaining foundation resources
print_info "Deploying foundation resources..."
# Note: storage.yaml is commented out - using hostPath volumes instead
kubectl apply -f 00-foundation/mongod-external.yaml
sleep 2

# Create log directory on host if it doesn't exist
print_info "Creating log directory on host..."
sudo mkdir -p /mnt/data/open5gs-logs
sudo chmod 777 /mnt/data/open5gs-logs
print_success "Log directory ready"

# Step 2: ConfigMaps
print_info "Creating ConfigMaps..."
kubectl apply -f 01-configmaps/
sleep 5

# Step 3: NRF (must be first)
print_info "Deploying NRF..."
kubectl apply -f 02-control-plane/nrf.yaml

print_info "Waiting for NRF to be ready..."
if ! kubectl wait --for=condition=ready pod -l app=nrf -n open5gs --timeout=60s; then
    print_error "NRF failed to start"
    kubectl logs -l app=nrf -n open5gs --tail=50
    exit 1
fi
print_success "NRF is ready"

# Step 4: SCP
print_info "Deploying SCP..."
kubectl apply -f 02-control-plane/scp.yaml

print_info "Waiting for SCP to be ready..."
if ! kubectl wait --for=condition=ready pod -l app=scp -n open5gs --timeout=60s; then
    print_error "SCP failed to start"
    kubectl logs -l app=scp -n open5gs --tail=50
    exit 1
fi
print_success "SCP is ready"

# Step 5: Control Plane NFs
print_info "Deploying control plane NFs..."
kubectl apply -f 02-control-plane/udr.yaml
kubectl apply -f 02-control-plane/udm.yaml
kubectl apply -f 02-control-plane/ausf.yaml
kubectl apply -f 02-control-plane/pcf.yaml
kubectl apply -f 02-control-plane/nssf.yaml

print_info "Waiting for control plane to be ready..."
if ! kubectl wait --for=condition=ready pod -l component=control-plane -n open5gs --timeout=90s; then
    print_warn "Some control plane NFs may not be ready"
    kubectl get pods -n open5gs
fi
print_success "Control plane is ready"

# Step 6: Session Management - AMF
print_info "Deploying AMF..."
kubectl apply -f 03-session-mgmt/amf.yaml

print_info "Waiting for AMF..."
if ! kubectl wait --for=condition=ready pod -l app=amf -n open5gs --timeout=60s; then
    print_error "AMF failed to start"
    kubectl logs -l app=amf -n open5gs --tail=50
    exit 1
fi
print_success "AMF is ready"

# Step 7: User Plane
print_info "Deploying UPF..."
kubectl apply -f 04-user-plane/upf.yaml

print_info "Waiting for UPF..."
if ! kubectl wait --for=condition=ready pod -l app=upf -n open5gs --timeout=60s; then
    print_error "UPF failed to start"
    kubectl logs -l app=upf -n open5gs --tail=50
    exit 1
fi
print_success "UPF is ready"

# Step 8: Session Management - SMF
print_info "Deploying SMF..."
kubectl apply -f 03-session-mgmt/smf.yaml

print_info "Waiting for SMF..."
if ! kubectl wait --for=condition=ready pod -l app=smf -n open5gs --timeout=60s; then
    print_error "SMF failed to start"
    kubectl logs -l app=smf -n open5gs --tail=50
    exit 1
fi
print_success "Session management is ready"

# Summary
print_success "========================================="
print_success "Open5GS Deployment Complete!"
print_success "========================================="
echo ""
print_info "Pod Status:"
kubectl get pods -n open5gs -o wide

echo ""
print_info "Services:"
kubectl get svc -n open5gs

echo ""
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
print_info "AMF NGAP Endpoint: ${NODE_IP}:38412"
print_info "Configure your gNB to connect to: ${NODE_IP}:38412"

echo ""
print_info "Useful commands:"
echo "  View logs: kubectl logs -f <pod-name> -n open5gs"
echo "  Exec into pod: kubectl exec -it <pod-name> -n open5gs -- bash"
echo "  Check UPF TUN: kubectl exec -it upf-0 -n open5gs -- ip addr show"