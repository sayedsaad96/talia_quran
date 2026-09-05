from pathlib import Path
import re, sys

root = Path(__file__).resolve().parents[1]
skill = (root / 'SKILL.md').read_text(encoding='utf-8')
discovery = (root / 'references/discovery-coverage.md').read_text(encoding='utf-8')
playbook = (root / 'references/runtime-playbook.md').read_text(encoding='utf-8')
combined = '\n'.join([skill, discovery, playbook])

required = [
    'version: 2.1.0',
    'Autonomous Discovery',
    'application graph',
    'Coverage Reconciliation',
    'Release Evidence',
    'adb devices',
    'flutter devices',
    'INCOMPLETE RUNTIME AUDIT',
    'READY FOR RELEASE',
    'talia_quran',
]
missing = [x for x in required if x.lower() not in combined.lower()]
if missing:
    print('FAIL missing contract text:', missing)
    sys.exit(1)

# The discovery model must not seed QA with named product features/domains.
forbidden = [
    '## Quran Navigation',
    '## Mushaf / Reader Experience',
    '## Audio / Recitation',
    '## Memorization',
    '## Search / Discovery',
    '## Startup and Onboarding',
]
found = [x for x in forbidden if x in discovery]
if found:
    print('FAIL hard-coded feature domains remain:', found)
    sys.exit(1)

front = re.match(r'^---\n(.*?)\n---\n', skill, re.S)
if not front:
    print('FAIL missing YAML frontmatter')
    sys.exit(1)

required_files = [
    'README.md',
    'references/runtime-playbook.md',
    'references/discovery-coverage.md',
    'references/setup.md',
    'templates/pre_release_audit.md',
    'templates/application_graph.md',
    'templates/capability_inventory.md',
    'templates/unreachable_implementation.md',
    'templates/regression_report.md',
    'scripts/check-qa-env.ps1',
    'scripts/check-qa-env.sh',
    'tests/skill-contract.md',
]
missing_files = [p for p in required_files if not (root / p).exists()]
if missing_files:
    print('FAIL missing files:', missing_files)
    sys.exit(1)

# Old v2 feature-specific coverage/template files must not ship.
old_files = [
    'references/talia-quran-coverage.md',
    'templates/feature_inventory.md',
    'templates/runtime_audit.md',
    'templates/unreachable_features.md',
]
leftovers = [p for p in old_files if (root / p).exists()]
if leftovers:
    print('FAIL v2 leftovers:', leftovers)
    sys.exit(1)

# Keep the core skill concise; details belong in references.
words = len(re.findall(r'\b\w+[\w-]*\b', skill))
if words > 500:
    print(f'FAIL SKILL.md too large: {words} words')
    sys.exit(1)

print(f'PASS: Talia Quran Runtime QA v2.1 contract ({words} SKILL.md words)')
