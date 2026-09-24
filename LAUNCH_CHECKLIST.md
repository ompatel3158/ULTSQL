# ULTSQL Launch & Hygiene Checklist

Track progress towards a production-ready, credible, and polished release of **ULTSQL**.

---

## 🔴 Priority 1: License & Legal Clarity

- [x] **Switch License to FSL (Functional Source License)**
  - Adopted [FSL-1.1-MIT](https://fsl.software/) in `LICENSE` and `LICENSE.md`.
  - *Why:* Protects against cloud resellers/monetization wrapping while converting to standard open source after 2 years.
- [x] **Set Explicit Copyright Holder**
  - Named `Om Patel <ompatel3158@gmail.com>` as copyright holder in `LICENSE`, `LICENSE.md`, and `LICENSE-FAQ.md`.
- [x] **Add "License History" Section in `README.md`**
  - Documented:
    - `1.0.0`: MIT
    - `1.0.1` to `1.0.17`: BSD-3
    - `1.0.18+`: FSL-1.1-MIT
- [x] **Fix License Metadata Across All Package Registries**
  - [x] `pubspec.yaml` (pub.dev)
  - [x] `bindings/nodejs/package.json` (npm) -> `FSL-1.1-MIT`
  - [x] `bindings/python/pyproject.toml` & `setup.py` (PyPI) -> `FSL-1.1-MIT`
  - [x] `bindings/rust/Cargo.toml` (crates.io) -> `FSL-1.1-MIT`
- [x] **Drop Mandatory Attribution Clause**
  - Removed "Powered by ULTSQL" forced attribution requirement; updated `LICENSE-FAQ.md` to reflect this.

---

## 🟠 Priority 2: Package Hygiene & Build Integrity

- [ ] **Audit & Test Every Install Command on a Clean Environment**
  - Validate that each install command in docs actually succeeds:
    - [ ] `pip install ultsql` (once PyPI updated)
    - [ ] `npm install ultsql` (once npm updated)
    - [ ] Go module (`go get github.com/ompatel3158/ULTSQL/bindings/go`)
    - [ ] Cargo crate (`cargo add ultsql`)
    - [ ] Docker image (`docker run ...`)
    - [ ] `curl | bash` script (`install.sh` / `install.ps1`)
  - *Action:* Keep docs synchronized with actively maintained install targets.
- [x] **Clean Up Dependencies in `pubspec.yaml`**
  - Removed unused Flutter boilerplate template dependencies (`cupertino_icons: ^1.0.8`).
  - Added `.pubignore` to exclude scratch files, test databases, and local artifacts from pub publishing.
- [ ] **Synchronize Version Numbers**
  - Confirm versions are aligned across GitHub tags/releases and `pubspec.yaml` (currently `1.0.22+`).
- [x] **Fix Analyzer Warnings (`dart analyze .`)**
  - Resolved analyzer warnings and configured excludes in `analysis_options.yaml`; verified with `dart analyze .` (0 issues).
- [ ] **Establish Verified Publisher on pub.dev**
  - Link a custom domain (e.g. `ultsql.dev` or personal domain) to establish verified publisher status.

---

## 🟡 Priority 3: README & Benchmark Realism

- [x] **Audit "Zero-Dependency" Claim**
  - Replaced absolute "zero-dependency" with "zero native C/C++ dependencies (Pure Dart engine)" to accurately account for `ffi`.
- [x] **Lead Benchmarks with Disk-Mode Numbers**
  - Placed disk persistence benchmarks upfront ahead of in-memory metrics.
  - Added explicit hardware specifications (Core i7-13650HX, 16GB DDR5, 1TB NVMe Gen 5 SSD) and dataset size (100,000 rows, ~18.5 MB footprint).
- [x] **Clarify Vector Search Benchmark Scope**
  - Documented dataset size: 10,000 768-dim embeddings with >99% Recall@10 against brute-force baseline.
- [x] **Reclassify Searchable Encryption**
  - Relabeled XOR-based search from "encryption" to "Deterministic Obfuscation (XOR Fast Matching)" with explicit cryptographic security warning advising users to use AES-256-CTR for true encryption.
- [x] **Tone Down Hype Language**
  - Removed exaggerated buzzwords ("Ultra-High Performance", "Ultra-Fast", etc.) in favor of concrete engineering facts.
- [x] **Add Explicit "Limitations" Section**
  - Documented single-node architecture (no distributed consensus), wildcard `LIKE` page scan behavior, multi-process file locking semantics, and experimental subsystems.
- [x] **Add Visual Onboarding & Quickstart**
  - Added 5-line quickstart directly below top header.
- [x] **Add Pro/Cloud Waitlist Link**
  - Added waitlist sign-up link in README header.

---

## 🔵 Priority 4: Old Releases Cleanup

- [ ] **Yank & Deprecate Outdated / Broken Releases**
  - [ ] Yank obsolete versions on PyPI (`pip` / twine / web UI).
  - [ ] Run `npm deprecate ultsql@<ver> "Please upgrade to latest"` for broken npm releases.
  - [ ] Clean up redundant or broken GitHub pre-releases/releases.
  - *(Note: pub.dev versions and public git commit history cannot be deleted, which is normal and acceptable).*

---

## 🟢 Priority 5: Launch Verification & Validation

- [x] **Provide Reproducible Benchmark Suite**
  - Referenced `dart run tool/benchmarks/benchmark_live_comparison.dart` in the README so users can verify performance independently.
- [x] **Add Pro/Cloud Waitlist Link**
  - Added in header and disclosure section.
