#!/usr/bin/env python3
"""
UltSQL Python Wheel Builder
Builds platform-specific wheels containing the native compiled UltSQL binary.
Supported target tags:
  - win_amd64
  - manylinux_2_28_x86_64
  - manylinux_2_28_aarch64
  - macosx_11_0_x86_64
  - macosx_11_0_arm64
"""

import argparse
import os
import shutil
import stat
import subprocess
import sys
from pathlib import Path

PLATFORM_MAP = {
    "windows-x64": {
        "tag": "win_amd64",
        "bin_name": "ultsql.exe",
        "patterns": ["*windows*x64*.exe", "*windows*.exe"],
    },
    "linux-x64": {
        "tag": "manylinux_2_28_x86_64",
        "bin_name": "ultsql",
        "patterns": ["*linux*x64*", "*ubuntu*latest*", "*linux-x86_64*"],
    },
    "linux-arm64": {
        "tag": "manylinux_2_28_aarch64",
        "bin_name": "ultsql",
        "patterns": ["*linux*arm64*", "*linux*aarch64*"],
    },
    "macos-x64": {
        "tag": "macosx_11_0_x86_64",
        "bin_name": "ultsql",
        "patterns": ["*macos*x64*", "*darwin*x64*"],
    },
    "macos-arm64": {
        "tag": "macosx_11_0_arm64",
        "bin_name": "ultsql",
        "patterns": ["*macos*arm64*", "*darwin*arm64*"],
    },
}


def build_single_wheel(binary_path: Path, platform_tag: str, out_dir: Path):
    python_dir = Path(__file__).resolve().parent
    pkg_bin_dir = python_dir / "src" / "ultsql" / "bin"
    pkg_bin_dir.mkdir(parents=True, exist_ok=True)

    # Clean existing binaries in bin dir
    for f in pkg_bin_dir.iterdir():
        if f.is_file():
            f.unlink()

    # Determine binary destination name
    dest_name = "ultsql.exe" if "win" in platform_tag else "ultsql"
    dest_path = pkg_bin_dir / dest_name

    print(f"[*] Copying {binary_path} -> {dest_path}")
    shutil.copy2(binary_path, dest_path)

    # Ensure executable permissions on Unix
    if "win" not in platform_tag:
        dest_path.chmod(dest_path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    # Run setup.py bdist_wheel with plat-name
    cmd = [
        sys.executable,
        str(python_dir / "setup.py"),
        "bdist_wheel",
        f"--plat-name={platform_tag}",
        f"--dist-dir={out_dir}",
    ]
    print(f"[>] Running: {' '.join(cmd)}")
    subprocess.check_call(cmd, cwd=str(python_dir))


def main():
    parser = argparse.ArgumentParser(description="Build UltSQL platform-specific wheels.")
    parser.add_argument("--binary", type=str, help="Path to single binary")
    parser.add_argument("--platform", type=str, help="Target platform tag (e.g. win_amd64, manylinux_2_28_x86_64)")
    parser.add_argument("--all-from", type=str, help="Directory containing compiled binaries for all platforms")
    parser.add_argument("--out-dir", type=str, default="dist", help="Output directory for wheels")
    parser.add_argument("--build-sdist", action="store_true", help="Also build source distribution (sdist)")

    args = parser.parse_args()
    python_dir = Path(__file__).resolve().parent
    out_dir = (python_dir / args.out_dir).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    if args.binary and args.platform:
        build_single_wheel(Path(args.binary), args.platform, out_dir)
    elif args.all_from:
        search_dir = Path(args.all_from).resolve()
        print(f"[*] Searching for platform binaries in: {search_dir}")
        for plat_key, info in PLATFORM_MAP.items():
            matched_file = None
            for pattern in info["patterns"]:
                matches = list(search_dir.rglob(pattern))
                # filter out non-files or directories
                matches = [m for m in matches if m.is_file() and not m.name.endswith(".whl") and not m.name.endswith(".tar.gz")]
                if matches:
                    matched_file = matches[0]
                    break

            if matched_file:
                print(f"[+] Found binary for {plat_key} ({info['tag']}): {matched_file}")
                build_single_wheel(matched_file, info["tag"], out_dir)
            else:
                print(f"[-] Warning: No binary matching patterns for {plat_key} in {search_dir}")
    else:
        # Fallback to local default build
        print("No --binary or --all-from provided. Checking build/bin/ultsql(.exe)...")
        local_bin = python_dir.parents[1] / "build" / "bin" / ("ultsql.exe" if sys.platform == "win32" else "ultsql")
        if local_bin.exists():
            current_tag = "win_amd64" if sys.platform == "win32" else "manylinux_2_28_x86_64"
            build_single_wheel(local_bin, current_tag, out_dir)
        else:
            print("[x] No local binary found to package.")
            sys.exit(1)

    if args.build_sdist:
        print("[*] Building sdist...")
        cmd = [sys.executable, str(python_dir / "setup.py"), "sdist", f"--dist-dir={out_dir}"]
        subprocess.check_call(cmd, cwd=str(python_dir))

    print(f"\n[*] Artifacts in {out_dir}:")
    for artifact in out_dir.iterdir():
        size_mb = artifact.stat().st_size / (1024 * 1024)
        print(f" - {artifact.name} ({size_mb:.2f} MB)")


if __name__ == "__main__":
    main()
