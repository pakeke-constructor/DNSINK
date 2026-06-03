import os
import glob
import re

_DIR = os.path.join(os.path.dirname(__file__), "coding_style")

def _read(name):
    with open(os.path.join(_DIR, name), "r", encoding="utf-8") as f:
        return f.read()

def _load_coding_style():
    guidelines = _read("_guidelines.md")
    example_files = sorted(glob.glob(os.path.join(_DIR, "[0-9]*.md")))
    examples = []
    for path in example_files:
        basename = os.path.splitext(os.path.basename(path))[0]
        name = re.sub(r"^\d+-", "", basename)
        content = _read(os.path.basename(path))
        examples.append(f'<example name="{name}">\n{content}\n</example>')
    examples_block = "\n\n".join(examples)
    return (
        f"\n<coding_guidelines>\n"
        f"{guidelines}\n"
        f"\n<examples>\n"
        f"\n{examples_block}\n"
        f"\n</examples>\n"
        f"</coding_guidelines>\n"
    )

SYSTEM_PROMPT_CODING_STYLE = _load_coding_style()
