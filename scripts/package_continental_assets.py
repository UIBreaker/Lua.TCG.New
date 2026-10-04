import json
from pathlib import Path
from zipfile import ZipFile, ZIP_STORED

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / 'docs/asset_manifest.json').read_text(encoding='utf-8'))
assert manifest['completion']['generated'] == 157 and not manifest['completion']['missing']
files = [root / a['file'] for a in manifest['assets']]
files += [root / 'docs' / name for name in (
    'asset_manifest.json', 'continental_asset_inventory.json',
    'CONTINENTAL_ART_BIBLE.md', 'CONTINENTAL_ASSET_PROMPTS.md',
    'CONTINENTAL_ASSET_DELIVERY.md', 'CONTINENTAL_VALIDATION.md',
    'continental_reference.png',
)]
files += sorted((root / 'docs').glob('continental_catalog_*.png'))
files += sorted((root / 'docs').glob('illustrated_*.png'))
archive = root / 'docs/continental_assets.zip'
with ZipFile(archive, 'w', compression=ZIP_STORED) as bundle:
    for file in files:
        bundle.write(file, file.relative_to(root).as_posix())
print(f'{len(manifest["assets"])} assets packaged; {archive.stat().st_size:,} bytes')
