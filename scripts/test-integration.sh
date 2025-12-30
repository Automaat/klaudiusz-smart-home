#!/usr/bin/env bash
# Integration test runner for local development
# Run this before pushing to main to catch issues early

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}Klaudiusz Smart Home - Integration Test Runner${NC}"
echo -e "${BLUE}==================================================${NC}"
echo ""

# Function to print status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "success" ]; then
        echo -e "${GREEN}✓${NC} $message"
    elif [ "$status" = "error" ]; then
        echo -e "${RED}✗${NC} $message"
    elif [ "$status" = "info" ]; then
        echo -e "${BLUE}ℹ${NC} $message"
    elif [ "$status" = "warning" ]; then
        echo -e "${YELLOW}⚠${NC} $message"
    fi
}

# Parse arguments
RUN_STATIC=true
RUN_INTEGRATION=true
VERBOSE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --static-only)
            RUN_INTEGRATION=false
            shift
            ;;
        --integration-only)
            RUN_STATIC=false
            shift
            ;;
        --verbose)
            VERBOSE="--show-trace"
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --static-only        Run only fast static checks"
            echo "  --integration-only   Run only slow integration tests"
            echo "  --verbose           Show detailed Nix trace"
            echo "  --help              Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                         # Run all tests"
            echo "  $0 --static-only           # Quick check before commit"
            echo "  $0 --integration-only      # Test VM before pushing to main"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run '$0 --help' for usage"
            exit 1
            ;;
    esac
done

# Check if we're in the right directory
if [ ! -f "flake.nix" ]; then
    print_status error "Not in repository root (flake.nix not found)"
    exit 1
fi

print_status info "Running in: $(pwd)"
echo ""

# Run static tests
if [ "$RUN_STATIC" = true ]; then
    print_status info "Running static tests (fast)..."
    echo ""

    if nix build .#checks.x86_64-linux.all-static-tests $VERBOSE --max-jobs auto; then
        print_status success "Static tests passed"
    else
        print_status error "Static tests failed"
        exit 1
    fi
    echo ""
fi

# Run integration tests
if [ "$RUN_INTEGRATION" = true ]; then
    print_status info "Running integration tests (slow, ~5-10 min)..."
    print_status warning "This will boot a VM and test all services"
    echo ""

    if nix build .#checks.x86_64-linux.all-integration-tests $VERBOSE --max-jobs auto; then
        print_status success "Integration tests passed"
    else
        print_status error "Integration tests failed"
        exit 1
    fi
    echo ""
fi

# Summary
echo -e "${BLUE}==================================================${NC}"
if [ "$RUN_STATIC" = true ] && [ "$RUN_INTEGRATION" = true ]; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    echo ""
    print_status info "Safe to push to main"
elif [ "$RUN_STATIC" = true ]; then
    echo -e "${GREEN}Static tests passed! ✓${NC}"
    echo ""
    print_status info "Run with --integration-only to test VM"
elif [ "$RUN_INTEGRATION" = true ]; then
    echo -e "${GREEN}Integration tests passed! ✓${NC}"
    echo ""
    print_status info "Configuration will deploy successfully"
fi
echo -e "${BLUE}==================================================${NC}"
