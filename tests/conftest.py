"""Pytest configuration and fixtures for tests."""

import sys
from pathlib import Path

import pytest

# Add custom_components to Python path for imports
project_root = Path(__file__).parent.parent
custom_components_path = project_root / "custom_components"
sys.path.insert(0, str(custom_components_path.parent))


@pytest.fixture(autouse=True)
def reset_imports():
    """Reset imports between tests to avoid state leakage."""
    import importlib

    yield

    # Clean up custom_components imports
    modules_to_remove = [
        key for key in sys.modules.keys()
        if key.startswith("custom_components.deepgram_stt")
    ]
    for module in modules_to_remove:
        sys.modules.pop(module, None)
