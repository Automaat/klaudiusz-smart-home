#!/usr/bin/env python3
"""Convert JSON to YAML with proper handling of large nested structures."""

import json
import sys
import yaml


def main():
    """Read JSON from stdin and write YAML to stdout."""
    try:
        data = json.load(sys.stdin)
        yaml.dump(
            data,
            sys.stdout,
            default_flow_style=False,
            allow_unicode=True,
            sort_keys=False,
            width=float("inf"),
        )
    except Exception as e:
        print(f"Error converting JSON to YAML: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
