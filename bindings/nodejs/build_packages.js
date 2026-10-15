#!/usr/bin/env node
/**
 * UltSQL NPM Platform Package Builder
 * Prepares and packages the platform-specific npm packages:
 *   - @ultsql/win32-x64
 *   - @ultsql/linux-x64
 *   - @ultsql/linux-arm64
 *   - @ultsql/darwin-x64
 *   - @ultsql/darwin-arm64
 */

const fs = require('fs');
const path = require('path');

const PLATFORMS = {
  'win32-x64': {
    binName: 'ultsql.exe',
    patterns: [/windows.*x64.*\.exe$/i, /windows.*\.exe$/i],
  },
  'linux-x64': {
    binName: 'ultsql',
    patterns: [/linux.*x64$/i, /ubuntu.*latest$/i, /linux-x86_64$/i],
  },
  'linux-arm64': {
    binName: 'ultsql',
    patterns: [/linux.*arm64$/i, /linux.*aarch64$/i],
  },
  'darwin-x64': {
    binName: 'ultsql',
    patterns: [/macos.*x64$/i, /darwin.*x64$/i],
  },
  'darwin-arm64': {
    binName: 'ultsql',
    patterns: [/macos.*arm64$/i, /darwin.*arm64$/i],
  },
};

function copyBinary(src, dest) {
  const dir = path.dirname(dest);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  fs.copyFileSync(src, dest);
  if (!dest.endsWith('.exe')) {
    fs.chmodSync(dest, 0o755);
  }
  console.log(`[*] Copied ${src} -> ${dest}`);
}

function findMatchingBinary(searchDir, patterns) {
  function walk(current) {
    const entries = fs.readdirSync(current, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(current, entry.name);
      if (entry.isDirectory()) {
        const found = walk(fullPath);
        if (found) return found;
      } else if (entry.isFile()) {
        for (const pattern of patterns) {
          if (pattern.test(entry.name)) {
            return fullPath;
          }
        }
      }
    }
    return null;
  }
  return walk(searchDir);
}

function main() {
  const args = process.argv.slice(2);
  let allFromDir = null;
  let targetPlat = null;
  let singleBin = null;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--all-from' && i + 1 < args.length) {
      allFromDir = path.resolve(args[++i]);
    } else if (args[i] === '--platform' && i + 1 < args.length) {
      targetPlat = args[++i];
    } else if (args[i] === '--binary' && i + 1 < args.length) {
      singleBin = path.resolve(args[++i]);
    }
  }

  const rootNpmDir = path.join(__dirname, 'npm');

  if (targetPlat && singleBin) {
    if (!PLATFORMS[targetPlat]) {
      console.error(`Unknown platform: ${targetPlat}`);
      process.exit(1);
    }
    const dest = path.join(rootNpmDir, targetPlat, 'bin', PLATFORMS[targetPlat].binName);
    copyBinary(singleBin, dest);
    return;
  }

  if (allFromDir) {
    console.log(`[*] Resolving binaries from: ${allFromDir}`);
    for (const [platKey, info] of Object.entries(PLATFORMS)) {
      const found = findMatchingBinary(allFromDir, info.patterns);
      if (found) {
        const dest = path.join(rootNpmDir, platKey, 'bin', info.binName);
        copyBinary(found, dest);
      } else {
        console.warn(`[-] Warning: No binary matching patterns for ${platKey} in ${allFromDir}`);
      }
    }
    return;
  }

  // Default: check repo build directory for local platform
  const localExe = process.platform === 'win32' ? 'ultsql.exe' : 'ultsql';
  const localBin = path.resolve(__dirname, '..', '..', 'build', 'bin', localExe);
  if (fs.existsSync(localBin)) {
    const currentPlat = `${process.platform}-${process.arch}`;
    if (PLATFORMS[currentPlat]) {
      const dest = path.join(rootNpmDir, currentPlat, 'bin', PLATFORMS[currentPlat].binName);
      copyBinary(localBin, dest);
    }
  } else {
    console.log('[-] No local binary found to copy.');
  }
}

if (require.main === module) {
  main();
}
