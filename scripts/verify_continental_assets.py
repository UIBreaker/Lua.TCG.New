import json
import sys
from collections import Counter, defaultdict
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[1]
path=ROOT/'docs/asset_manifest.json'
manifest=json.loads(path.read_text(encoding='utf-8'))
groups=defaultdict(list)
missing=[]
for a in manifest['assets']:
    if a['id']=='hand_expansion':
        a['previous_paths']=['assets/vouchers/v_hand_size.png','assets/cards/hand_expansion.png']
        a['redesigned_from_existing']=True
    if a['group']=='voucher' or a['id']=='healing_potion':
        a['previous_ui_renderer']='ui/shop_display.lua'
        a['replaces_code_drawn_art']=True
    file=ROOT/a['file']
    if not file.exists(): missing.append(a['id']);continue
    with Image.open(file) as image:
        assert image.format=='PNG', a['id']
        w,h=image.size
        assert abs(w/h-2/3)<0.01 and w>=512 and h>=768,(a['id'],w,h)
        a['dimensions']=[w,h]
        a['status']='generated'
        receipt=ROOT/'docs/continental_generated'/f"{a['id']}.json"
        if receipt.exists(): a['generation']=json.loads(receipt.read_text(encoding='utf-8'))
        else: a['generation']={'generator_source':'built-in image_gen pilot','prompt':a['prompt']}
        groups[a['group']].append((a,image.convert('RGB').copy()))
manifest['completion']={'generated':sum(map(len,groups.values())),'total':len(manifest['assets']),'missing':missing}
manifest['reference_file']='docs/continental_reference.png'
legacy=[]
for folder in ('cards','consumables','deities','equipment','hands','packs','vouchers','scene/enemy_cards','scene/enemies'):
    for file in (ROOT/'assets'/folder).rglob('*.png'):
        if 'continental' not in file.parts: legacy.append(file.relative_to(ROOT).as_posix())
manifest['legacy_files_retained']=legacy
path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
font=ImageFont.truetype(str(ROOT/'fonts/arial.ttf'),14)
summary=[]
for group,items in groups.items():
    cols=6 if len(items)>12 else 3
    rows=(len(items)+cols-1)//cols
    sheet=Image.new('RGB',(cols*170,rows*266),(9,15,24))
    draw=ImageDraw.Draw(sheet)
    for i,(a,image) in enumerate(items):
        image.thumbnail((150,225))
        x=(i%cols)*170+10;y=(i//cols)*266+4
        sheet.paste(image,(x,y))
        draw.text((x,y+229),a['name'][:24],font=font,fill=(225,226,218))
        draw.text((x,y+246),a['id'][:25],font=font,fill=(153,178,181))
    sheet.save(ROOT/f'docs/continental_catalog_{group}.png')
    summary.append(f"- {group}: {len(items)} PNG — [contact sheet](continental_catalog_{group}.png)")
report='# Continental asset delivery\n\n'+f"Generated: {manifest['completion']['generated']} / {len(manifest['assets'])}.\n\n"+'\n'.join(summary)
report+='\n\n## Full inventory\n\n| Group | ID | Name | Output | Replaces existing raster |\n|---|---|---|---|---|\n'
report+='\n'.join(f"| {a['group']} | {a['id']} | {a['name']} | [{Path(a['file']).name}](../{a['file']}) | {'yes' if a['redesigned_from_existing'] else 'new dedicated art'} |" for a in manifest['assets'])
(ROOT/'docs/CONTINENTAL_ASSET_DELIVERY.md').write_text(report,encoding='utf-8')
print(json.dumps(manifest['completion']))
if missing and '--partial' not in sys.argv: raise SystemExit(1)
