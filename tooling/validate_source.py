from pathlib import Path
import re, sys
root=Path(__file__).resolve().parents[1]
required=['pubspec.yaml','lib/main.dart','lib/state/app_controller.dart','lib/services/api_service.dart','lib/services/sync_service.dart','docs/README_AR.md','docs/API_CONTRACT.md','tooling/bootstrap_android.sh','tooling/bootstrap_android.ps1','test/models_test.dart']
missing=[x for x in required if not (root/x).exists()]
if missing:
    print('MISSING',missing);sys.exit(1)

def scrub(s):
    s=re.sub(r"'''[\s\S]*?'''|\"\"\"[\s\S]*?\"\"\"|'(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\"", "", s)
    s=re.sub(r'//.*', '', s)
    return s
for p in root.glob('lib/**/*.dart'):
    s=scrub(p.read_text(encoding='utf-8'))
    if any(s.count(a)!=s.count(b) for a,b in [('(',')'),('[',']'),('{','}')]):
        print('BALANCE_FAIL',p);sys.exit(2)
    if '\x00' in s:
        print('NUL',p);sys.exit(3)
print('source_structure_check=PASS')
print('dart_files=',len(list(root.glob('lib/**/*.dart'))))
print('tests=',len(list(root.glob('test/**/*.dart'))))
