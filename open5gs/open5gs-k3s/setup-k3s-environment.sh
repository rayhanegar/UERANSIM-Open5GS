#!/bin/bash
################################################################################
# Open5GS Kubernetes (K3s) Environment Setup Script
# 
# This script prepares a Ubuntu system for Open5GS deployment on K3s:
# - Installs required packages
# - Loads necessary kernel modules
# - Configures IP forwarding
# - Creates required directories
# - Installs K3s with Flannel CNI
# - Configures kubectl access
#
# Usage: sudo ./setup-k3s-environment.sh
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
print_header() {
    echo ""
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}================================${NC}"
    echo ""
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${GREEN}▸${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Detect the actual user (not root)
get_actual_user() {
    if [ -n "$SUDO_USER" ]; then
        echo "$SUDO_USER"
    else
        echo "$USER"
    fi
}

# Step 1: Check and install required packages
install_packages() {
    print_header "Step 1: Checking and Installing Required Packages"
    
    local packages=(
        "curl"
        "wget"
        "git"
        "net-tools"
        "iptables"
        "socat"
        "conntrack"
        "jq"
    )
    
    local missing_packages=()
    
    # Check which packages are missing
    for pkg in "${packages[@]}"; do
        if ! dpkg -l | grep -qw "^ii.*$pkg"; then
            missing_packages+=("$pkg")
        else
            print_step "$pkg is already installed"
        fi
    done
    
    # Install missing packages
    if [ ${#missing_packages[@]} -gt 0 ]; then
        print_info "Missing packages: ${missing_packages[*]}"
        print_info "Updating apt cache..."
        apt update -qq
        
        print_info "Installing missing packages..."
        apt install -y "${missing_packages[@]}"
        
        print_success "Installed packages: ${missing_packages[*]}"
    else
        print_success "All required packages are already installed"
    fi
}

# Step 2: Load kernel modules
load_kernel_modules() {
    print_header "Step 2: Loading Kernel Modules"
    
    local modules=("sctp" "ip_tables" "ip6_tables" "br_netfilter")
    local modules_loaded=0
    
    for mod in "${modules[@]}"; do
        if lsmod | grep -qw "^$mod"; then
            print_step "$mod module already loaded"
        else
            print_info "Loading $mod module..."
            modprobe "$mod" 2>/dev/null || {
                print_warn "Failed to load $mod module (may not be available)"
                continue
            }
            modules_loaded=$((modules_loaded + 1))
            print_step "$mod module loaded"
        fi
    done
    
    # Persist kernel modules
    local modules_conf="/etc/modules-load.d/open5gs-k3s.conf"
    if [ ! -f "$modules_conf" ]; then
        print_info "Creating persistent module configuration..."
        cat > "$modules_conf" <<EOF
# Kernel modules for Open5GS on K3s
sctp
ip_tables
ip6_tables
br_netfilter
EOF
        print_success "Created $modules_conf"
    else
        print_step "Module configuration already exists at $modules_conf"
    fi
    
    if [ $modules_loaded -gt 0 ]; then
        print_success "Loaded $modules_loaded kernel module(s)"
    else
        print_success "All kernel modules already loaded"
    fi
}

# Step 3: Enable IP forwarding
enable_ip_forwarding() {
    print_header "Step 3: Enabling IP Forwarding"
    
    local changed=0
    
    # Enable IPv4 forwarding
    if sysctl net.ipv4.ip_forward | grep -q "= 0"; then
        print_info "Enabling IPv4 forwarding..."
        sysctl -w net.ipv4.ip_forward=1 >/dev/null
        changed=$((changed + 1))
        print_step "IPv4 forwarding enabled"
    else
        print_step "IPv4 forwarding already enabled"
    fi
    
    # Enable IPv6 forwarding
    if sysctl net.ipv6.conf.all.forwarding | grep -q "= 0"; then
        print_info "Enabling IPv6 forwarding..."
        sysctl -w net.ipv6.conf.all.forwarding=1 >/dev/null
        changed=$((changed + 1))
        print_step "IPv6 forwarding enabled"
    else
        print_step "IPv6 forwarding already enabled"
    fi
    
    # Enable bridge netfilter
    if sysctl net.bridge.bridge-nf-call-iptables | grep -q "= 0" 2>/dev/null; then
        print_info "Enabling bridge netfilter..."
        sysctl -w net.bridge.bridge-nf-call-iptables=1 >/dev/null
        changed=$((changed + 1))
        print_step "Bridge netfilter enabled"
    else
        print_step "Bridge netfilter already enabled"
    fi
    
    # Persist sysctl settings
    local sysctl_conf="/etc/sysctl.d/99-open5gs-k3s.conf"
    if [ ! -f "$sysctl_conf" ] || [ $changed -gt 0 ]; then
        print_info "Creating persistent sysctl configuration..."
        cat > "$sysctl_conf" <<EOF
# Sysctl settings for Open5GS on K3s
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
EOF
        sysctl -p "$sysctl_conf" >/dev/null 2>&1
        print_success "Created $sysctl_conf"
    else
        print_step "Sysctl configuration already exists at $sysctl_conf"
    fi
    
    if [ $changed -gt 0 ]; then
        print_success "Enabled $changed sysctl setting(s)"
    else
        print_success "All sysctl settings already enabled"
    fi
}

# Step 4: Create log directories
create_directories() {
    print_header "Step 4: Creating Required Directories"
    
    local log_dir="/mnt/data/open5gs-logs"
    
    if [ -d "$log_dir" ]; then
        print_step "Log directory already exists: $log_dir"
    else
        print_info "Creating log directory: $log_dir"
        mkdir -p "$log_dir"
        chmod 777 "$log_dir"
        print_success "Created log directory: $log_dir"
    fi
    
    # Show directory info
    print_info "Directory details:"
    ls -ld "$log_dir"
}

# Step 5: Install K3s with Flannel
install_k3s() {
    print_header "Step 5: Installing K3s with Flannel CNI"
    
    # Check if K3s is already installed
    if command -v k3s &> /dev/null; then
        print_warn "K3s is already installed"
        print_info "Current K3s version:"
        k3s --version | head -n 1
        
        read -p "Do you want to reinstall K3s? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping K3s installation"
            return 0
        fi
        
        print_info "Uninstalling existing K3s..."
        /usr/local/bin/k3s-uninstall.sh 2>/dev/null || true
        sleep 3
    fi
    
    print_info "Installing K3s with Flannel (host-gw backend)..."
    print_info "This may take a few minutes..."
    
    # Install K3s with specific configuration
    curl -sfL https://get.k3s.io | sh -s - server \
        --disable traefik \
        --disable servicelb \
        --write-kubeconfig-mode 644 \
        --kube-proxy-arg proxy-mode=ipvs \
        --flannel-backend=host-gw \
        --cluster-cidr=10.42.0.0/16 \
        --service-cidr=10.43.0.0/16
    
    # Wait for K3s to be ready
    print_info "Waiting for K3s to be ready..."
    local max_wait=60
    local count=0
    while ! systemctl is-active --quiet k3s; do
        sleep 2
        count=$((count + 2))
        if [ $count -ge $max_wait ]; then
            print_error "K3s failed to start within ${max_wait} seconds"
            print_info "Check logs with: sudo journalctl -u k3s -n 50"
            exit 1
        fi
    done
    
    print_success "K3s installed successfully"
    
    # Display K3s version
    print_info "K3s version:"
    k3s --version | head -n 1
    
    # Display network configuration
    print_info "Network configuration:"
    echo "  Pod CIDR:     10.42.0.0/16"
    echo "  Service CIDR: 10.43.0.0/16"
    echo "  CNI:          Flannel (host-gw)"
}

# Step 6: Configure kubectl
configure_kubectl() {
    print_header "Step 6: Configuring kubectl Access"
    
    local kubeconfig="/etc/rancher/k3s/k3s.yaml"
    
    # Check if kubeconfig exists
    if [ ! -f "$kubeconfig" ]; then
        print_error "K3s kubeconfig not found at $kubeconfig"
        exit 1
    fi
    
    print_step "K3s kubeconfig found at $kubeconfig"
    
    # Test kubectl access
    export KUBECONFIG="$kubeconfig"
    if k3s kubectl get nodes &>/dev/null; then
        print_success "kubectl access verified"
        
        # Display cluster info
        print_info "Cluster nodes:"
        k3s kubectl get nodes
    else
        print_error "kubectl access test failed"
        exit 1
    fi
}

# Step 7: Setup kubectl alias and reload
setup_kubectl_alias() {
    print_header "Step 7: Setting up kubectl Alias"
    
    local actual_user=$(get_actual_user)
    local user_home=$(eval echo ~$actual_user)
    local bashrc="$user_home/.bashrc"
    
    print_info "Configuring for user: $actual_user"
    print_info "User home: $user_home"
    
    local kubeconfig_export="export KUBECONFIG=/etc/rancher/k3s/k3s.yaml"
    local kubectl_alias="alias kubectl='k3s kubectl'"
    
    local changes_made=0
    
    # Check and add KUBECONFIG export
    if grep -q "^export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" "$bashrc" 2>/dev/null; then
        print_step "KUBECONFIG already set in $bashrc"
    else
        print_info "Adding KUBECONFIG to $bashrc..."
        echo "" >> "$bashrc"
        echo "# K3s kubectl configuration" >> "$bashrc"
        echo "$kubeconfig_export" >> "$bashrc"
        chown "$actual_user:$actual_user" "$bashrc"
        changes_made=$((changes_made + 1))
        print_step "KUBECONFIG added to $bashrc"
    fi
    
    # Check and add kubectl alias
    if grep -q "^alias kubectl=" "$bashrc" 2>/dev/null; then
        print_step "kubectl alias already exists in $bashrc"
    else
        print_info "Adding kubectl alias to $bashrc..."
        echo "$kubectl_alias" >> "$bashrc"
        chown "$actual_user:$actual_user" "$bashrc"
        changes_made=$((changes_made + 1))
        print_step "kubectl alias added to $bashrc"
    fi
    
    if [ $changes_made -gt 0 ]; then
        print_success "Made $changes_made change(s) to $bashrc"
        print_warn "Run 'source ~/.bashrc' to apply changes in current shell"
    else
        print_success "All configurations already in place"
    fi
    
    # Create a convenience script for easy access
    local kubectl_script="/usr/local/bin/kubectl"
    if [ ! -f "$kubectl_script" ]; then
        print_info "Creating kubectl convenience script..."
        cat > "$kubectl_script" <<'EOF'
#!/bin/bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
exec k3s kubectl "$@"
EOF
        chmod +x "$kubectl_script"
        print_success "Created $kubectl_script"
    else
        print_step "kubectl convenience script already exists"
    fi
}

# Verify installation
verify_installation() {
    print_header "Verification"
    
    print_info "Checking K3s status..."
    if systemctl is-active --quiet k3s; then
        print_success "✓ K3s service is running"
    else
        print_error "✗ K3s service is not running"
        return 1
    fi
    
    print_info "Checking nodes..."
    if k3s kubectl get nodes 2>/dev/null | grep -q "Ready"; then
        print_success "✓ Cluster node is Ready"
    else
        print_warn "✗ Cluster node is not Ready yet (may need more time)"
    fi
    
    print_info "Checking system pods..."
    local pods_ready=$(k3s kubectl get pods -n kube-system 2>/dev/null | grep -c "Running" || echo 0)
    if [ "$pods_ready" -gt 0 ]; then
        print_success "✓ $pods_ready system pod(s) running"
    else
        print_warn "✗ System pods not ready yet (may need more time)"
    fi
    
    print_info "Checking Flannel..."
    if k3s kubectl get pods -n kube-system -l app=flannel 2>/dev/null | grep -q "Running"; then
        print_success "✓ Flannel CNI is running"
    else
        print_warn "✗ Flannel CNI not ready yet (may need more time)"
    fi
}

# Display summary and next steps
show_summary() {
    print_header "Installation Complete!"
    
    local node_ip=$(hostname -I | awk '{print $1}')
    
    echo -e "${GREEN}Summary:${NC}"
    echo "  ✓ Required packages installed"
    echo "  ✓ Kernel modules loaded and persisted"
    echo "  ✓ IP forwarding enabled"
    echo "  ✓ Log directory created: /mnt/data/open5gs-logs"
    echo "  ✓ K3s installed with Flannel CNI"
    echo "  ✓ kubectl configured and aliased"
    echo ""
    
    echo -e "${CYAN}Cluster Information:${NC}"
    echo "  Node IP:      $node_ip"
    echo "  Pod CIDR:     10.42.0.0/16"
    echo "  Service CIDR: 10.43.0.0/16"
    echo "  CNI:          Flannel (host-gw)"
    echo ""
    
    echo -e "${CYAN}Next Steps:${NC}"
    echo "  1. Reload your shell environment:"
    echo -e "     ${YELLOW}source ~/.bashrc${NC}"
    echo ""
    echo "  2. Verify kubectl works:"
    echo -e "     ${YELLOW}kubectl get nodes${NC}"
    echo -e "     ${YELLOW}kubectl get pods -A${NC}"
    echo ""
    echo "  3. Proceed with Open5GS deployment:"
    echo "     - Update MongoDB IP in 00-foundation/mongodb-external.yaml"
    echo "     - Update AMF NGAP address to: $node_ip"
    echo "     - Build and import container images"
    echo "     - Run: ./deploy.sh"
    echo ""
    
    echo -e "${CYAN}Useful Commands:${NC}"
    echo "  Check K3s status:    sudo systemctl status k3s"
    echo "  View K3s logs:       sudo journalctl -u k3s -f"
    echo "  Get cluster info:    kubectl cluster-info"
    echo "  Uninstall K3s:       sudo /usr/local/bin/k3s-uninstall.sh"
    echo ""
}

# Main execution
main() {
    print_header "Open5GS K3s Environment Setup"
    
    print_info "This script will prepare your system for Open5GS deployment on K3s"
    print_info "Starting setup process..."
    
    # Run all steps
    check_root
    install_packages
    load_kernel_modules
    enable_ip_forwarding
    create_directories
    install_k3s
    configure_kubectl
    setup_kubectl_alias
    
    # Wait a bit for K3s to stabilize
    print_info "Waiting for K3s to fully initialize..."
    sleep 10
    
    verify_installation
    show_summary
    
    print_success "Setup complete! Your system is ready for Open5GS deployment."
}

# Run main function
main "$@"