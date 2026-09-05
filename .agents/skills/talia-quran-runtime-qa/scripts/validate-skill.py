from pathlib import Path
import re, sys

root = Path(__file__).resolve().parents[1]
skill = root / "SKILL.md"
text = skill.read_text(encoding="utf-8")
errors = []

m = re.match(r"---\n(.*?)\n---\n", text, re.S)
if not m:
    errors.append("Missing YAML frontmatter")
else:
    fm = m.group(1)
    name = re.search(r"^name:\s*(.+)$", fm, re.M)
    desc = re.search(r"^description:\s*(.+)$", fm, re.M)
    if not name: errors.append("Missing name")
    elif name.group(1).strip() != root.name: errors.append("name must match folder")
    if not desc: errors.append("Missing description")
    elif not desc.group(1).strip().startswith("Use when"): errors.append("description should start with 'Use when'")

for rel in [
    "references/runtime-playbook.md", "references/talia-coverage.md", "references/setup.md",
    "templates/feature_inventory.md", "templates/runtime_audit.md",
    "templates/unreachable_features.md", "templates/regression_report.md",
    "scripts/check-qa-env.ps1", "scripts/check-qa-env.sh", "tests/skill-scenarios.md"
]:
    if not (root / rel).exists(): errors.append(f"Missing {rel}")

required = ["runtime", "Reachability audit", "Do not delete, weaken, skip", "No device available"]
for phrase in required:
    if phrase not in text: errors.append(f"Missing required contract phrase: {phrase}")

if errors:
    print("FAIL")
    for e in errors: print("-", e)
    sys.exit(1)

print("PASS: skill structure and core contracts validated")
print("SKILL.md words:", len(text.split()))
