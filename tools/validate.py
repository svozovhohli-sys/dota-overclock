#!/usr/bin/env python3
"""OVERCLOCK static validator.

Checks everything that can be checked without Dota 2 / Hammer:

  * Lua  syntax            -> luaparser, if installed (optional)
  * JS   syntax            -> `node --check`, if node is on PATH
  * XML  well-formedness   -> xml.dom.minidom (stdlib)
  * KV   brace balance     -> simple // comment-stripping counter
  * require() paths        -> every require("overclock...") resolves to a file

Exit code is non-zero if any hard check fails. Lua/JS checks are skipped (with a
notice) when the corresponding tool is unavailable, so this also runs in a bare
environment.
"""
import glob
import os
import re
import shutil
import subprocess
import sys
import xml.dom.minidom as minidom

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAME = os.path.join(ROOT, "game", "dota_addons", "overclock")
CONTENT = os.path.join(ROOT, "content", "dota_addons", "overclock")

results = []  # (ok: bool, label: str)


def record(ok, label):
    results.append((ok, label))
    print(("PASS " if ok else "FAIL ") + label)


def check_lua():
    files = sorted(glob.glob(os.path.join(GAME, "**", "*.lua"), recursive=True))
    try:
        from luaparser import ast
    except ImportError:
        print("SKIP Lua  (luaparser not installed)")
        return
    bad = 0
    for f in files:
        try:
            ast.parse(open(f, encoding="utf-8").read())
        except Exception as e:  # noqa: BLE001
            bad += 1
            print("  FAIL", os.path.relpath(f, ROOT), "->", e)
    record(bad == 0, f"Lua syntax ({len(files) - bad}/{len(files)})")


def check_js():
    files = sorted(glob.glob(os.path.join(CONTENT, "**", "*.js"), recursive=True))
    node = shutil.which("node")
    if not node:
        print("SKIP JS   (node not on PATH)")
        return
    bad = 0
    for f in files:
        r = subprocess.run([node, "--check", f], capture_output=True, text=True)
        if r.returncode != 0:
            bad += 1
            print("  FAIL", os.path.relpath(f, ROOT), "->", r.stderr.strip())
    record(bad == 0, f"JS syntax ({len(files) - bad}/{len(files)})")


def check_xml():
    files = sorted(glob.glob(os.path.join(CONTENT, "**", "*.xml"), recursive=True))
    bad = 0
    for f in files:
        try:
            minidom.parse(f)
        except Exception as e:  # noqa: BLE001
            bad += 1
            print("  FAIL", os.path.relpath(f, ROOT), "->", e)
    record(bad == 0, f"XML well-formed ({len(files) - bad}/{len(files)})")


def check_kv():
    files = sorted(
        glob.glob(os.path.join(GAME, "scripts", "npc", "*.txt"))
        + glob.glob(os.path.join(GAME, "resource", "localization", "*.txt"))
    )
    bad = 0
    for f in files:
        s = re.sub(r"//[^\n]*", "", open(f, encoding="utf-8").read())
        if s.count("{") != s.count("}"):
            bad += 1
            print("  FAIL", os.path.relpath(f, ROOT), "-> unbalanced braces")
    record(bad == 0, f"KV brace balance ({len(files) - bad}/{len(files)})")


def check_requires():
    vscripts = os.path.join(GAME, "scripts", "vscripts")
    missing = []
    for f in glob.glob(os.path.join(vscripts, "**", "*.lua"), recursive=True):
        src = open(f, encoding="utf-8").read()
        for mod in re.findall(r'require\("([^"]+)"\)', src):
            rel = mod.replace(".", os.sep)
            if os.path.exists(os.path.join(vscripts, rel + ".lua")):
                continue
            if os.path.exists(os.path.join(vscripts, rel, "init.lua")):
                continue
            missing.append(f"{mod}  (in {os.path.relpath(f, ROOT)})")
    for m in missing:
        print("  MISSING", m)
    record(not missing, f"require() paths ({'all resolve' if not missing else str(len(missing)) + ' missing'})")


def main():
    print("OVERCLOCK validator — root:", ROOT)
    check_lua()
    check_js()
    check_xml()
    check_kv()
    check_requires()
    failed = [label for ok, label in results if not ok]
    print("-" * 50)
    if failed:
        print("FAILED:", ", ".join(failed))
        return 1
    print("ALL HARD CHECKS PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
