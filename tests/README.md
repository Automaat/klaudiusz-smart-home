# Tests

## Overview

Test suite for Klaudiusz Smart Home project.

## Test Types

### Integration Tests

- **`homelab-integration-test.py`**: VM-based integration tests
  - Service health checks
  - HA startup validation
  - Log error detection

## Running Tests

### Integration Tests (NixOS VM)

```bash
# Build and run integration tests
nix build .#checks.x86_64-linux.homelab-integration

# View test results
cat result/test-results.log
```

## Test Structure

```text
tests/
├── conftest.py              # Pytest configuration and shared fixtures
├── homelab-integration-test.py  # VM integration tests (NixOS)
└── README.md                # This file
```

## CI Integration

Tests run automatically in GitHub Actions on PR creation.

- **Static checks**: Nix config validation, YAML syntax
- **Integration tests**: VM-based tests with full HA stack
- **Gate**: `production` branch only updates when all tests pass
