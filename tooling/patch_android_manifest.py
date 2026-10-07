from pathlib import Path
import xml.etree.ElementTree as ET
p=Path('android/app/src/main/AndroidManifest.xml')
if not p.exists():
    raise SystemExit('Run flutter create first so android/app/src/main/AndroidManifest.xml exists.')
ET.register_namespace('android','http://schemas.android.com/apk/res/android')
tree=ET.parse(p); root=tree.getroot(); ns='{http://schemas.android.com/apk/res/android}'
perm='android.permission.INTERNET'
if not any(x.get(ns+'name')==perm for x in root.findall('uses-permission')):
    root.insert(0, ET.Element('uses-permission',{ns+'name':perm}))
app=root.find('application')
if app is not None:
    app.set(ns+'usesCleartextTraffic','true')
tree.write(p,encoding='utf-8',xml_declaration=True)
print('Patched',p)
