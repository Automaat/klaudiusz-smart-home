# Tests

## Overview

Test suite for Klaudiusz Smart Home project.

## Test Types

### Unit Tests

- **`test_deepgram_stt.py`**: Deepgram STT custom component tests
  - Entity initialization
  - Audio stream processing
  - Config flow (manual + auto-import)
  - Error handling
  - Event handlers

### Integration Tests

- **`homelab-integration-test.py`**: VM-based integration tests
  - Service health checks
  - HA startup validation
  - Log error detection

## Running Tests

### Unit Tests (pytest)

```bash
# Install dev dependencies
pip install -r requirements-dev.txt

# Run all unit tests
pytest

# Run specific test file
pytest tests/test_deepgram_stt.py

# Run with coverage
pytest --cov=custom_components/deepgram_stt

# Run specific test class
pytest tests/test_deepgram_stt.py::TestDeepgramSTTEntity

# Run specific test
pytest tests/test_deepgram_stt.py::TestDeepgramSTTEntity::test_entity_initialization
```

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
├── test_deepgram_stt.py     # Deepgram STT unit tests
├── homelab-integration-test.py  # VM integration tests (NixOS)
└── README.md                # This file
```

## Writing Tests

### Unit Test Template

```python
import pytest
from unittest.mock import Mock, AsyncMock

class TestMyComponent:
    """Test my component."""

    @pytest.mark.asyncio
    async def test_async_function(self):
        """Test async function."""
        result = await my_async_function()
        assert result == expected_value

    def test_sync_function(self):
        """Test sync function."""
        result = my_sync_function()
        assert result == expected_value
```

### Key Testing Patterns

**Mock Deepgram SDK:**

```python
with patch("custom_components.deepgram_stt.stt.DeepgramClient", return_value=mock_client):
    result = await entity.process_audio()
```

**Mock Home Assistant:**

```python
mock_hass = MagicMock(spec=HomeAssistant)
mock_hass.async_add_executor_job = AsyncMock()
```

**Test async event handlers:**

```python
registered_handlers = {}
def capture_handler(event, handler):
    registered_handlers[event] = handler

mock_connection.on = MagicMock(side_effect=capture_handler)
```

## CI Integration

Tests run automatically in GitHub Actions on PR creation.

- **Static checks**: Nix config validation, YAML syntax
- **Unit tests**: pytest suite (requires implementation)
- **Integration tests**: VM-based tests with full HA stack
- **Gate**: `production` branch only updates when all tests pass

## Troubleshooting

**Import errors:**

```bash
# Ensure custom_components in path
export PYTHONPATH="${PYTHONPATH}:${PWD}"
pytest
```

**Async test failures:**

```bash
# Check pytest-asyncio installed
pip install pytest-asyncio>=0.23.0
```

**Deepgram SDK not found:**

```bash
# Install from requirements
pip install -r requirements-dev.txt
```
