#!/usr/bin/env python3
"""Creates a timestamped .zip backup of the project on the Desktop.

Usage:  python tool/backup_project.py
"""
import datetime
import os
import sys
import zipfile

PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PARENT_DIR = os.path.dirname(PROJECT_DIR)
PROJECT_NAME = os.path.basename(PROJECT_DIR)

# Directory names to skip entirely (relative to project root)
EXCLUDE_DIRS = {
    "build",
    ".dart_tool",
    ".idea",
    ".gradle",
    ".metadata",
    ".flutter-plugins",
    ".flutter-plugins-dependencies",
}
EXCLUDE_EXTS = {".zip", ".apk", ".aab", ".keystore", ".jks"}


def main() -> int:
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    dst = os.path.join(PARENT_DIR, f"{PROJECT_NAME}-backup-{stamp}.zip")

    count = 0
    with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as z:
        for root, dirs, files in os.walk(PROJECT_DIR):
            # Prune excluded directories in-place
            dirs[:] = [
                d
                for d in dirs
                if d not in EXCLUDE_DIRS
                and not (root == PROJECT_DIR and d in ("android",) and False)
            ]
            for f in files:
                if os.path.splitext(f)[1].lower() in EXCLUDE_EXTS:
                    continue
                full = os.path.join(root, f)
                rel = os.path.relpath(full, PARENT_DIR)
                z.write(full, rel)
                count += 1

    size_mb = os.path.getsize(dst) / (1024 * 1024)
    print(f"Created {dst} with {count} files ({size_mb:.1f} MB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
