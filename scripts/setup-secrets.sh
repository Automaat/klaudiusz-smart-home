#!/usr/bin/env bash
set -euo pipefail

# ===========================================
# SOPS Secrets Setup Script
# ===========================================
# Run this during first installation to:
# 1. Generate age key
# 2. Update .sops.yaml with new public key
# 3. Create and encrypt secrets.yaml with dummy values

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
KEY_DIR="/var/lib/sops-nix"
KEY_FILE="$KEY_DIR/key.txt"
REPO_ROOT="/etc/nixos"
SOPS_CONFIG="$REPO_ROOT/.sops.yaml"
SECRETS_FILE="$REPO_ROOT/secrets/secrets.yaml"
TEMPLATE_FILE="$REPO_ROOT/secrets/secrets.yaml.template"

echo -e "${GREEN}=== SOPS Secrets Setup ===${NC}\n"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Error: This script must be run as root${NC}"
  echo "Usage: sudo $0"
  exit 1
fi

# Check if we're in installation environment or running on installed system
if [ ! -d "$REPO_ROOT" ]; then
  echo -e "${YELLOW}Note: /etc/nixos not found. Adjusting paths for local development...${NC}"
  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  SOPS_CONFIG="$REPO_ROOT/.sops.yaml"
  SECRETS_FILE="$REPO_ROOT/secrets/secrets.yaml"
  TEMPLATE_FILE="$REPO_ROOT/secrets/secrets.yaml.template"
  echo "Using repo root: $REPO_ROOT"
fi

# Step 1: Generate age key
echo "Step 1: Generating age key..."
if [ -f "$KEY_FILE" ]; then
  echo -e "${YELLOW}Age key already exists at $KEY_FILE${NC}"
else
  mkdir -p "$KEY_DIR"
  age-keygen -o "$KEY_FILE"
  chmod 600 "$KEY_FILE"
  echo -e "${GREEN}✓ Generated age key at $KEY_FILE${NC}"
fi

# Step 2: Get public key
echo -e "\nStep 2: Extracting public key..."
PUBKEY=$(age-keygen -y "$KEY_FILE")
echo -e "${GREEN}✓ Public key: $PUBKEY${NC}"

# Step 3: Update .sops.yaml
echo -e "\nStep 3: Updating .sops.yaml..."
# Replace the homelab public key with new one
sed -i.bak "s/- &homelab age[a-z0-9]*/- \&homelab $PUBKEY/" "$SOPS_CONFIG"
echo -e "${GREEN}✓ Updated .sops.yaml with new homelab key${NC}"

# Step 4: Create secrets.yaml from template
echo -e "\nStep 4: Creating secrets.yaml from template..."
if [ -f "$SECRETS_FILE" ]; then
  echo -e "${YELLOW}Warning: $SECRETS_FILE already exists${NC}"
  read -p "Overwrite? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping secrets.yaml creation"
    exit 0
  fi
fi

# Create secrets.yaml with dummy values
cat > "$SECRETS_FILE" <<EOF
# Auto-generated dummy secrets
# Replace with real values after installation

grafana-admin-password: "admin-change-me"
home-assistant-prometheus-token: "dummy-token-change-me"
telegram-bot-token: "123456789:ABCdefGHIjklMNOpqrsTUVwxyz-CHANGE-ME"
telegram-chat-id: "123456789"
EOF

echo -e "${GREEN}✓ Created $SECRETS_FILE${NC}"

# Step 5: Encrypt secrets.yaml
echo -e "\nStep 5: Encrypting secrets.yaml with SOPS..."
cd "$REPO_ROOT"
sops -e -i "$SECRETS_FILE"
echo -e "${GREEN}✓ Encrypted $SECRETS_FILE${NC}"

echo -e "\n${GREEN}=== Setup Complete ===${NC}"
echo -e "\n${YELLOW}IMPORTANT:${NC}"
echo "1. Age key location: $KEY_FILE"
echo "2. Public key: $PUBKEY"
echo "3. Secrets file encrypted with dummy values"
echo "4. Replace dummy values with real secrets:"
echo "   sops $SECRETS_FILE"
echo ""
echo "You can now run: nixos-rebuild switch --flake $REPO_ROOT#homelab"
