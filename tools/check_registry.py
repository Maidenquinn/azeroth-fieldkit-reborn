"""Validate the distribution using the official registry's own checker."""
from pathlib import Path
import argparse,importlib.util,json,tomllib,hashlib
base=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--registry',type=Path,required=True);a=p.parse_args()
spec=importlib.util.spec_from_file_location('registry_pin',a.registry/'tools/pin.py')
registry=importlib.util.module_from_spec(spec);spec.loader.exec_module(registry)
entry=tomllib.loads((base/'distribution/azeroth-fieldkit-reborn.toml').read_text(encoding='utf8'))
registry.check_fields(entry)
toc=(base/'AzerothFieldKitReborn/AzerothFieldKitReborn.toc').read_text(encoding='utf8')
version=next(s.split(':',1)[1].strip() for s in toc.splitlines() if s.startswith('## Version:'))
archive=base/'dist'/f'AzerothFieldKitReborn-{version}.zip'
data=archive.read_bytes();interfaces=registry.check_zip(entry['folders'],data)
result={'officialRegistryZipCheck':True,'interfaces':interfaces,'bytes':len(data),
        'sha256':hashlib.sha256(data).hexdigest(),'registryCommit':None,'liveGameTest':False}
import subprocess
result['registryCommit']=subprocess.check_output(['git','rev-parse','HEAD'],cwd=a.registry,text=True).strip()
(base/'dist/registry-validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
print(json.dumps(result))
