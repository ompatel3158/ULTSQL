"""
UltSQL Python Server Daemon Launcher
Allows Python users to start ULTSQL server directly from terminal via `ultsql-server`
"""
import sys
import subprocess

def main():
    """Launch ULTSQL server daemon."""
    print("🚀 Starting UltSQL Database Daemon...")
    args = sys.argv[1:]
    cmd = ["ultsql", "serve"] + args
    try:
        subprocess.run(cmd)
    except FileNotFoundError:
        print("💡 Tip: Ensure `ultsql` CLI is installed or run in embedded mode.")
        print("To install global CLI: dart pub global activate ultsql")

if __name__ == "__main__":
    main()
