#!/usr/bin/env python3
"""Sign a local build with a persistent, private development identity.

No certificate trust settings or default keychain/search-list changes are made.
The generated identity is for local builds only, not public distribution.
"""
import hashlib
import os
from pathlib import Path
import secrets
import shlex
import subprocess
import sys
import tempfile


def run(*args):
    result = subprocess.run(args, capture_output=True, text=True)
    if result.returncode:
        # Never print command arguments: security commands contain passphrases.
        raise SystemExit(f"{Path(args[0]).name} failed: {result.stderr.strip()}")
    return result.stdout


def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: sign-local.py /path/to/Ice.app")
    app = Path(sys.argv[1]).resolve(strict=True)
    os.umask(0o077)
    signing_dir = Path.home() / "Library/Application Support/IceLocalDevelopmentSigning"
    signing_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
    keychain = signing_dir / "ice-local.keychain-db"
    password_file = signing_dir / "keychain-password"
    certificate = signing_dir / "certificate.der"

    if not keychain.exists():
        if certificate.exists():
            raise SystemExit("Signing keychain is missing; restore it instead of replacing the existing identity.")
        password = secrets.token_hex(32)
        password_file.write_text(password)
        old_search_list = shlex.split(run("/usr/bin/security", "list-keychains", "-d", "user"))
        try:
            run("/usr/bin/security", "create-keychain", "-p", password, str(keychain))
        finally:
            run("/usr/bin/security", "list-keychains", "-d", "user", "-s", *old_search_list)
        with tempfile.TemporaryDirectory(dir=signing_dir) as temp:
            temp = Path(temp)
            key, pem, archive = (temp / name for name in ("key.pem", "cert.pem", "identity.p12"))
            run("/usr/bin/openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes",
                "-keyout", str(key), "-out", str(pem), "-days", "3650",
                "-subj", "/CN=Ice Local Development/",
                "-addext", "basicConstraints=critical,CA:FALSE",
                "-addext", "keyUsage=critical,digitalSignature",
                "-addext", "extendedKeyUsage=critical,codeSigning")
            run("/usr/bin/openssl", "pkcs12", "-export", "-inkey", str(key),
                "-in", str(pem), "-out", str(archive),
                "-passout", f"file:{password_file}")
            run("/usr/bin/security", "import", str(archive), "-k", str(keychain),
                "-P", password, "-T", "/usr/bin/codesign", "-x")
            run("/usr/bin/security", "set-key-partition-list", "-S", "apple-tool:",
                "-s", "-k", password, str(keychain))
            run("/usr/bin/openssl", "x509", "-in", str(pem), "-outform", "DER", "-out", str(certificate))

    if not password_file.exists() or not certificate.exists():
        raise SystemExit("Local signing setup is incomplete; do not replace the keychain automatically.")
    password = password_file.read_text().strip()
    fingerprint = hashlib.sha1(certificate.read_bytes()).hexdigest().upper()
    run("/usr/bin/security", "unlock-keychain", "-p", password, str(keychain))
    try:
        run("/usr/bin/codesign", "--force", "--sign", fingerprint,
            "--keychain", str(keychain), "--timestamp=none",
            "--preserve-metadata=entitlements,flags", str(app))
        run("/usr/bin/codesign", "--verify", "--deep", "--strict", str(app))
    finally:
        run("/usr/bin/security", "lock-keychain", str(keychain))
    print(f"Signed with persistent local identity: {app}")


if __name__ == "__main__":
    main()
