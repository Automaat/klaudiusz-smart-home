#!/usr/bin/env bash
set -euo pipefail

# Fix hardware-configuration.nix with actual partition UUIDs
# Run this on the homelab server after installation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HW_CONFIG="$REPO_ROOT/hosts/homelab/hardware-configuration.nix"

echo "==> Getting partition UUIDs..."
ROOT_UUID=$(blkid -s UUID -o value /dev/sda2)
BOOT_UUID=$(blkid -s UUID -o value /dev/sda1)
SWAP_UUID=$(blkid -s UUID -o value /dev/sda3)

echo "Root UUID: $ROOT_UUID"
echo "Boot UUID: $BOOT_UUID"
echo "Swap UUID: $SWAP_UUID"

echo ""
echo "==> Backing up hardware-configuration.nix..."
cp "$HW_CONFIG" "$HW_CONFIG.bak"

echo "==> Updating UUIDs in hardware-configuration.nix..."
sed -i "s|device = \"/dev/disk/by-uuid/be8a2e74-67aa-453c-8495-54f065e2bf30\"|device = \"/dev/disk/by-uuid/$ROOT_UUID\"|" "$HW_CONFIG"
sed -i "s|device = \"/dev/disk/by-uuid/7D3C-643D\"|device = \"/dev/disk/by-uuid/$BOOT_UUID\"|" "$HW_CONFIG"
sed -i "s|device = \"/dev/disk/by-uuid/08a8e3bc-5368-4dd1-9a32-7edaae2872be\"|device = \"/dev/disk/by-uuid/$SWAP_UUID\"|" "$HW_CONFIG"

echo "==> Verifying changes..."
echo ""
grep -A 2 "fileSystems" "$HW_CONFIG"
grep -A 2 "swapDevices" "$HW_CONFIG"

echo ""
echo "==> Done! Now run:"
echo "    nixos-rebuild switch --flake $REPO_ROOT#homelab"
