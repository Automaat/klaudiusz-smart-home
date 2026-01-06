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

# Export age key location for SOPS
export SOPS_AGE_KEY_FILE="$KEY_FILE"
echo -e "✓ SOPS_AGE_KEY_FILE=$SOPS_AGE_KEY_FILE"

# Step 3: Update .sops.yaml
echo -e "\nStep 3: Updating .sops.yaml..."
# Replace the homelab public key with new one
sed -i.bak "s/- &homelab age[a-z0-9]*/- \&homelab $PUBKEY/" "$SOPS_CONFIG"
echo -e "${GREEN}✓ Updated .sops.yaml with new homelab key${NC}"

# Step 4: Handle existing or create new secrets.yaml
echo -e "\nStep 4: Managing secrets.yaml..."
if [ -f "$SECRETS_FILE" ]; then
  # Check if file is already encrypted (contains "sops:" metadata)
  if grep -q "^sops:" "$SECRETS_FILE"; then
    echo -e "${YELLOW}Encrypted secrets.yaml exists${NC}"
    read -p "Re-encrypt with updated keys? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
      echo "Re-encrypting with updated keys..."
      cd "$REPO_ROOT"
      sops updatekeys -y "$SECRETS_FILE"
      echo -e "${GREEN}✓ Re-encrypted $SECRETS_FILE${NC}"
    else
      echo "Skipping re-encryption"
    fi
  else
    # Unencrypted file exists
    echo -e "${YELLOW}Unencrypted secrets.yaml exists${NC}"
    read -p "Encrypt it now? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
      cd "$REPO_ROOT"
      sops -e -i "$SECRETS_FILE"
      echo -e "${GREEN}✓ Encrypted $SECRETS_FILE${NC}"
    else
      echo "Skipping encryption"
    fi
  fi
else
  # Create new secrets.yaml from template
  echo "Creating secrets.yaml from template..."
  cat > "$SECRETS_FILE" <<EOF
# Auto-generated dummy secrets
# Replace with real values after installation

grafana-admin-password: "admin-change-me"
home-assistant-prometheus-token: "dummy-token-change-me"
telegram-bot-token: "123456789:ABCdefGHIjklMNOpqrsTUVwxyz-CHANGE-ME"
telegram-chat-id: "123456789"
EOF
  echo -e "${GREEN}✓ Created $SECRETS_FILE${NC}"

  echo "Encrypting secrets.yaml..."
  cd "$REPO_ROOT"
  sops -e -i "$SECRETS_FILE"
  echo -e "${GREEN}✓ Encrypted $SECRETS_FILE${NC}"
fi

echo -e "\n${GREEN}=== Setup Complete ===${NC}"
echo -e "\n${YELLOW}IMPORTANT:${NC}"
echo "1. Age key location: $KEY_FILE"
echo "2. Public key: $PUBKEY"

# Step 5: Git workflow
echo -e "\nStep 5: Git commit workflow..."
cd "$REPO_ROOT"

# Check if files changed
if git diff --quiet .sops.yaml secrets/secrets.yaml 2>/dev/null; then
  echo "No changes to commit"
else
  echo -e "${YELLOW}Files modified:${NC}"
  git status --short .sops.yaml secrets/secrets.yaml 2>/dev/null || true

  echo -e "\nStaging changes..."
  git add .sops.yaml secrets/secrets.yaml

  echo -e "${YELLOW}Ready to commit. Choose action:${NC}"
  echo "1) Commit automatically"
  echo "2) Show diff and exit (manual commit)"
  echo "3) Skip commit (not recommended - rebuild will fail)"
  read -p "Choice (1/2/3): " -n 1 -r
  echo

  case $REPLY in
    1)
      # Check git config
      if ! git config user.email >/dev/null 2>&1; then
        echo -e "${RED}Git user.email not configured${NC}"
        echo "Run: git config --global user.email 'you@example.com'"
        exit 1
      fi

      git commit -s -S -m "fix: update sops keys and encrypt secrets for homelab" || {
        echo -e "${YELLOW}Commit failed. Commit manually:${NC}"
        echo "  git commit -s -S -m 'fix: update sops keys and encrypt secrets'"
      }
      echo -e "${GREEN}✓ Committed${NC}"
      ;;
    2)
      echo -e "\n${YELLOW}Showing diff:${NC}"
      git diff --cached .sops.yaml secrets/secrets.yaml | head -30
      echo -e "\n${YELLOW}Commit manually:${NC}"
      echo "  git commit -s -S -m 'fix: update sops keys and encrypt secrets'"
      exit 0
      ;;
    3)
      git restore --staged .sops.yaml secrets/secrets.yaml
      echo -e "${RED}⚠ Changes unstaged - rebuild will fail with plain secrets${NC}"
      exit 1
      ;;
  esac
fi

echo -e "\n${GREEN}Next steps:${NC}"
echo "1. Edit secrets with real values:"
echo "   sops $SECRETS_FILE"
echo "2. Rebuild system:"
echo "   nixos-rebuild switch --flake $REPO_ROOT#homelab"
echo "3. Push changes:"
echo "   git push"
