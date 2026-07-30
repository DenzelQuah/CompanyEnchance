"""
Compatibility wrapper.

The actual ingestion script lives at `backend/scripts/insert_markdown_roadmap_knowledge.py`.
This file lets you run it from the repo root:

  python scripts/insert_markdown_roadmap_knowledge.py --file "...md" --source-doc-id "..."
"""

from __future__ import annotations

import runpy
import subprocess
import sys
from pathlib import Path


def main() -> None:
    repo_root = Path(__file__).resolve().parents[1]
    target = (
        Path(__file__).resolve().parents[1]
        / "backend"
        / "scripts"
        / "insert_markdown_roadmap_knowledge.py"
    )

    backend_venv_python = repo_root / "backend" / ".venv" / "Scripts" / "python.exe"
    if backend_venv_python.exists():
        current = Path(sys.executable).resolve()
        desired = backend_venv_python.resolve()
        if current != desired:
            raise SystemExit(
                subprocess.call([str(desired), str(target), *sys.argv[1:]])
            )

    runpy.run_path(str(target), run_name="__main__")


if __name__ == "__main__":
    main()
