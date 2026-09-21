#!/usr/bin/env python3
"""Verify a changed build still satisfies the original certificate requirement."""
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile


def signature(app):
    result = subprocess.run(["codesign", "-d", "-r-", "--verbose=4", str(app)],
                            capture_output=True, text=True, check=True)
    output = result.stdout + result.stderr
    requirement = re.search(r"^designated => (.+)$", output, re.M)
    cdhash = re.search(r"^CDHash=(.+)$", output, re.M)
    assert requirement and cdhash, "Expected a certificate-signed application"
    return requirement[1], cdhash[1]


app = Path(sys.argv[1]).resolve(strict=True)
before_requirement, before_hash = signature(app)
assert "certificate leaf" in before_requirement, "Must pin the signing certificate"
with tempfile.TemporaryDirectory(prefix="ice-signing-test-") as temp:
    changed = Path(temp) / "Ice.app"
    shutil.copytree(app, changed, symlinks=True)
    (changed / "Contents/Resources/SigningContinuityTest.txt").write_text("Changed build\n")
    subprocess.run([sys.executable, str(Path(__file__).with_name("sign-local.py")), str(changed)], check=True)
    after_requirement, after_hash = signature(changed)
    assert before_hash != after_hash, "The test must change the signed code hash"
    assert before_requirement == after_requirement, "The designated identity must remain unchanged"
    subprocess.run(["codesign", "--verify", "--strict", "-R", "=" + before_requirement, str(changed)], check=True)
print("PASS: changed build has a different code hash and satisfies the original signing requirement")
