#!/usr/bin/env python3
"""Check deepgram-sdk v5.3.1 API structure."""

import sys

try:
    import deepgram
    print(f"deepgram version: {deepgram.__version__}")
except Exception as e:
    print(f"Import deepgram failed: {e}")
    sys.exit(1)

# Check available imports
print("\nChecking imports:")

# Try core imports
try:
    from deepgram import AsyncDeepgramClient
    print("✓ AsyncDeepgramClient")
except Exception as e:
    print(f"✗ AsyncDeepgramClient: {e}")

try:
    from deepgram.core.events import EventType
    print("✓ EventType")
except Exception as e:
    print(f"✗ EventType: {e}")

# Try ListenV1MediaMessage imports
for path in [
    "deepgram.extensions.types.sockets",
    "deepgram.core.types.sockets",
    "deepgram.types.sockets",
    "deepgram.listen.v1.types",
]:
    try:
        module = __import__(path, fromlist=['ListenV1MediaMessage'])
        print(f"✓ {path}.ListenV1MediaMessage")
        print(f"  Available: {dir(module)}")
    except Exception as e:
        print(f"✗ {path}.ListenV1MediaMessage: {e}")

# Check connection object methods
print("\nChecking connection object methods:")
try:
    client = AsyncDeepgramClient(api_key="dummy_key_for_testing")
    print(f"✓ Created client")
    print(f"  listen: {hasattr(client, 'listen')}")
    if hasattr(client, 'listen'):
        print(f"  listen.v1: {hasattr(client.listen, 'v1')}")
        print(f"  listen.v2: {hasattr(client.listen, 'v2')}")
except Exception as e:
    print(f"✗ Client creation: {e}")
