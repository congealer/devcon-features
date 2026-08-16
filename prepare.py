#!/usr/bin/env python3
"""Bump Feature versions ahead of a release.

Pick the Features, pick a level for each, and the new version is written into
devcontainer-feature.json and the docs regenerated. It stops there: the version
is what decides whether 'make release' uploads anything, so the diff is left to
be read and committed rather than done for you.
"""

import json
import subprocess
import sys
from collections import OrderedDict
from pathlib import Path

try:
    import questionary
except ImportError:
    sys.exit("questionary is not installed - rebuild the dev container")

ROOT = Path(__file__).resolve().parent.parent


def metadata(feature):
    return ROOT / "src" / feature / "devcontainer-feature.json"


def current_version(feature):
    return json.loads(metadata(feature).read_text())["version"]


def candidates(version):
    """The version each level would produce, in the order they are offered."""
    major, minor, patch = (int(part) for part in version.split("."))
    return OrderedDict(
        major=f"{major + 1}.0.0",
        minor=f"{major}.{minor + 1}.0",
        patch=f"{major}.{minor}.{patch + 1}",
    )


def write_version(feature, version):
    """Rewrite the version alone, leaving the rest of the file's order intact."""
    path = metadata(feature)
    data = json.loads(path.read_text(), object_pairs_hook=OrderedDict)
    data["version"] = version
    path.write_text(json.dumps(data, indent=4, ensure_ascii=False) + "\n")


def main():
    features = sorted(d.name for d in (ROOT / "src").iterdir() if d.is_dir())
    if not features:
        sys.exit("no Features under src/")

    chosen = questionary.checkbox(
        "Features to bump",
        choices=[
            questionary.Choice(f"{f}  ({current_version(f)})", value=f)
            for f in features
        ],
    ).ask()
    if not chosen:
        sys.exit("nothing picked")

    # Asked per Feature rather than once: a release usually carries a different
    # kind of change to each one.
    picked = OrderedDict()
    for feature in chosen:
        current = current_version(feature)
        options = candidates(current)
        version = questionary.select(
            f"{feature} is {current}",
            choices=[
                questionary.Choice(f"{level}  {v}", value=v)
                for level, v in options.items()
            ],
        ).ask()
        if version is None:
            sys.exit("nothing picked")
        picked[feature] = (current, version)

    print()
    for feature, (current, version) in picked.items():
        write_version(feature, version)
        print(f"  {feature}  {current} -> {version}")

    # The generated README carries the description and the options rather than
    # the version, so this usually reports nothing. It runs anyway, because
    # publishing with the docs out of step is the thing worth avoiding.
    subprocess.run(["make", "docs"], cwd=ROOT, check=True, stdout=subprocess.DEVNULL)

    print()
    subprocess.run(["git", "--no-pager", "diff", "--stat"], cwd=ROOT, check=True)
    print("\nNothing is committed. Read the diff, then commit and 'make release'.")


if __name__ == "__main__":
    main()
