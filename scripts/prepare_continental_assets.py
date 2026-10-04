import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
assets = json.loads((ROOT / 'docs/continental_asset_inventory.json').read_text(encoding='utf-8'))
concepts = {
 'spirit_pebble':'A monumental stone guardian awakened above coastal cliffs, an amber pulse strengthening a fan of blank cards.',
 'spirit_ember':'One ember spirit emerging from a volcanic fissure, fanning controlled orange heat into a small hand of cards.',
 'spirit_blade':'One spectral western sword spirit above icy ruins, an echo blade touching each card in an arc.',
 'spirit_drum':'An ancient spectral war drum above storm cliffs, a visible circular thunder wave empowering a row of cards.',
 'spirit_pair':'Twin ghostly stag guardians joined by one living-green thread above the ancient forest, a balanced paired silhouette.',
 'spirit_straight':'Five stepping stone sword monoliths ascending in sequence toward a luminous portal across continental cliffs.',
 'spirit_flush':'A single great-tree spirit, five leaves of the same shape orbiting its luminous heart, forest green and gold.',
 'spirit_crown':'A blood-red phantom western crown above a fossil throne, three subdued royal silhouettes receiving its power.',
 'spirit_coin':'One ancient golden spirit coin floating above an expedition victory cairn, a restrained halo over the distant desert.',
 'gem_fire':'One faceted ember stone mounted on the spearhead of an expedition standard, volcanic ridge behind, a strong pointed silhouette.',
 'gem_blast':'One three-pronged bronze relic holding three amber stones, on a fossil altar, a controlled triangular pulse.',
 'mirror_adjacent':'One weathered western hand mirror reflecting two differently coloured card silhouettes on either side, coastal stone altar.',
 'storm_eye':'One circular storm-eye relic in a bronze setting, matching green fragments linked around it, wind-worn forest ruins.',
 'lucky_coin':'One antique gold coin with a simple triangular ace-like emblem, resting on a desert explorer map and an ancient stone ledge.',
 'ward_stone':'One shield-shaped blue rune stone, a small sheltering arc protecting two blank cards, icy mountain sanctuary.',
 'vitality_gem':'One living-green crystalline heart relic in a simple silver cradle, returning a light thread to a wounded expedition glove, great-tree roots.',
 'blood_ring':'One angular iron ring with a red garnet and a sharp thorn, a single drop of blood feeding controlled crimson light, fossil desert altar.',
 'void_catalyst':'One tangible black-violet crystalline catalyst in a bronze socket, a small focused eclipse within the crystal, lost floating-island ruins.',
 'spec_familiar':'One spectral owl guardian conjuring three royal card silhouettes while a sacrificed fourth crumbles, ancient forest ruins.',
 'spec_grim':'One western hooded death guardian presenting two luminous ace silhouettes, one sacrificed card falling to ash in a fossil desert.',
 'spec_incantation':'One ancient candle altar summoning four blank numbered-card silhouettes from a single dissolving card, ruined coastal crypt.',
 'spec_cryptid':'One strange deep-sea guardian reflected twice across still water, a central blank card splitting into two perfect echoes.',
 'spec_immolate':'One volcanic offering bowl consuming a fan of five blank cards and revealing a small pile of antique coins, controlled orange flame.',
 'spec_sigil':'One monolithic rune seal unifying several differently shaped blank cards into matching silhouettes, living-green forest stone circle.',
 'spec_ouija':'One ancient western spirit board with a single luminous pointer aligning blank cards, a shadow swallowing one empty card slot, violet ruins.',
 'spec_black_hole':'One violet eclipse opening above floating islands, nine quiet paths of light ascending from continental biomes into the singularity.',
 'spell_aura':'One life-light halo from a giant ancient tree surrounding a spectral guardian card, restrained gold and green atmospheric illumination.',
 'spell_ectoplasm':'One emerald ghost rising from coastal crypt ruins and opening an extra spectral card slot while one mortal card fades.',
 'spell_ankh':'One ancient bronze ankh-life relic in a bone-desert sanctuary, reflecting one spirit card into its twin while distant unused cards fade.',
 'spell_hex':'One weathered curse monolith focusing a subtle prismatic aura onto a single spirit card while other cards fall into shadow, violet eclipse ruins.',
 'seal_blood':'One readable blood-red wax-like sigil stamped by an iron signet over a blank card, a wounded adventurer glove at a volcanic altar.',
 'seal_prophecy':'One blue eye-shaped bronze seal revealing a faint future enemy silhouette inside its circular lens, icy observatory altar.',
 'seal_ashen':'One ash-grey stamp pressing a blank card into a final orange ember strike, fossil crypt and quiet smoke.',
 'seal_bounty':'One antique bounty medallion beside an expedition trophy and two clear gold coins, bone-desert stone altar.',
 'seal_anchor':'One weathered bronze anchor seal binding a blank card with a teal light thread to an explorer hand, enormous coastal cliffs.',
 'seal_purifying':'One ivory sun-shaped seal dissolving a single black curse thread from a blank card, quiet waterfall shrine.',
 'cons_speed_single':'One blank expedition card cutting through cyan wind, one clear directional afterimage, a wind-carved coastal arch.',
 'cons_speed_team':'One coordinated fan of blank expedition cards swept forward by a single silver-cyan wind current over a mountain pass.',
 'cons_evolution':'One blank relic card awakening upward from a living-green seed-shaped crystal, three ascending stages of a simple runic frame, white gold light.',
 'edition_foil':'One blank relic card being gilded by a simple antique gold press, metallic gold reflections and a quiet desert workshop.',
 'edition_holographic':'One blank relic card in an ancient light chamber, a spectral blue second surface appearing above it, icy observatory.',
 'edition_polychrome':'One blank relic card crossing a single crystal prism, three controlled coloured bands on the surface, floating-island laboratory.',
 'ed_foil':'One blank relic card being gilded by an antique gold press, reflective metallic foil, quiet desert workshop.',
 'ed_holo':'One blank relic card in an ancient light chamber, a spectral blue echo surface, icy observatory.',
 'ed_poly':'One blank relic card crossing a single crystal prism, restrained spectral surface bands, floating-island laboratory.',
 'buffoon':'One weathered spirit reliquary with a tall arched lid, a single guardian-shaped light rising from it, giant-tree roots.',
 'arcana':'One sturdy expedition equipment coffer with iron clasps, a clearly visible stone relic and tool inside, ruined desert workshop.',
 'standard':'One rectangular explorer card case opening on a coastal ledge, three blank cards standing upright, ocean and colossal cliffs.',
 'spectral':'One split living-crystal transformation reliquary reconstructing a blank card between two distinct material states, green and antique gold.',
 'edition':'One antique card-gilding press with a hinged coffer base, a blank card beneath its luminous plate, ivory stone and controlled metallic light.',
 'joker_edition':'One tall spirit-shrine chest with a circular portal lid, a spectral guardian card receiving violet and ghost-blue energy, lost floating-island temple.',
 'enchantment':'One low western arcane altar chest with a clear runic ring and a single levitating blank card, blue crystal channels, quiet coastal ruins.',
 'seal':'One heavy ivory stone stamping chest with a large red signet press suspended over a blank card, solemn bone-desert sanctuary.',
 'celestial':'One round astrolabe reliquary chest with a domed lid opening toward distant planets above icy peaks, navy and antique brass.',
 'hand_styles':'One weathered western expedition codex coffer with a simple sword clasp, several tactical blank-card formations on stone beside it.',
 'high_card':'One lone western explorer with a raised short sword on a cliff ledge, a clear solitary silhouette and vast continent beyond.',
 'pair':'Two matching western swords crossed in a clean central silhouette at an old forest expedition camp.',
 'two_pair':'Two distinct pairs of western shields arranged symmetrically on a fossil altar, four readable large shapes.',
 'three_of_a_kind':'Three matching bronze sword monoliths resonating together in a triangular formation in a desert ruin.',
 'straight':'Five ascending stone steps with one western blade on each, a continuous expedition path crossing a giant waterfall.',
 'flush':'Five matching leaf-shaped shields forming one coherent green defensive crest beneath the luminous ancient tree.',
 'full_house':'One western stone fortress crest formed from three matching towers joined to two matching smaller towers, clear grouped silhouette.',
 'four_of_a_kind':'Four matching western sword monoliths surrounding one square amber core in volcanic ruins, bold fourfold symmetry.',
 'straight_flush':'Five matching silver swords ascending together along an icy causeway toward one ancient light portal.',
 'planet_supernova':'One restrained golden supernova above the continent, a single brighter beam selecting one of nine small stone training shrines.',
 'planet_black_hole':'One violet eclipse above floating ruins, nine quiet upgrade paths converging toward the singularity.',
 'hand_expansion':'One opened explorer leather card wallet with an additional empty pocket unfolding, old map and coastal expedition camp.',
 'healing_potion':'One practical western glass healing flask with green life light, silver stopper and a simple leather strap, ancient tree roots.',
 'card_back':'A symmetrical expedition atlas sigil: one antique bronze compass enclosing the outline of a mysterious continent, navy ocean, subtle forest-green and violet accents. No ornate border.',
}
planets={'planet_pluto':'small distant frost-grey world','planet_mercury':'small quick silver-blue world','planet_uranus':'tilted pale turquoise ringed world','planet_venus':'warm golden clouded world','planet_saturn':'large amber ringed world','planet_jupiter':'banded deep-red giant world','planet_earth':'living green-blue continental world','planet_mars':'rust-red desert world','planet_neptune':'deep ocean-blue world'}
for key,subject in planets.items():
    concepts[key]=f'One {subject} above an ancient continental observatory. Below, a clear runic training shrine awakens the specific poker formation stated in the ability; quiet navy sky, controlled celestial light.'
biomes={'hearts':'volcanic foothills and red sunset ruins, iron and warm crimson','diamonds':'fossil desert and antique western ruins, brass and sand gold','clubs':'ancient forest and glowing giant-tree roots, moss green and bronze','spades':'glacial mountains and weathered fortress ruins, ice blue and silver'}
roles={2:'scout',3:'pathfinder',4:'rune surveyor',5:'expedition guard',6:'field alchemist',7:'relic hunter',8:'war drummer',9:'arcane cartographer',10:'expedition captain',11:'western herald',12:'western expedition queen',13:'western expedition king',14:'ancient expedition champion'}
family_style={
 'spn':'Supernatural continental phenomenon or guardian; distinct from a tangible item.',
 'itm':'One tangible central relic, wearable or tool; large silhouette, quiet discovery-site background.',
 'chest':'One clearly identifiable chest/container mechanism; its silhouette must differ from every other chest.',
 'speed':'Acceleration, horizontal motion and controlled cyan/silver wind, not growth.',
 'evolution':'Upward awakening and progressive growth, white gold and living green, not speed streaks.',
 'playing':'A Western expedition figure or relic expressing the exact ability. Leave upper-left and lower-right index areas quiet.',
 'enemy':'One continental creature or Western antagonist, strong central silhouette, full atmospheric setting, no UI or indices.',
}
base=('Use case: stylized-concept. Create ONE production game card illustration, full-bleed portrait 2:3, high-resolution PNG. '
 'Art direction: Cinematic Dark-Fantasy Expedition / Continental Relic Card Design. The master world is a colossal mysterious continent: '
 'deep navy ocean with leviathans and monumental coastal cliffs; glacial peaks; green plains, rivers and waterfalls; ancient forests and a glowing giant tree; '
 'fossil deserts; orange volcanic wastes; violet eclipse, floating islands and lost Western ruins. Use one biome and one controlled magic accent per image. '
 'Painterly cinematic illustration, clean large shapes, one primary focus, medium detail, atmospheric depth and restrained rim light; readable at 64px. '
 'Basic but beautiful, not anime, not a chaotic poster. No text, letters, numbers, card frame, borders, logos, watermark or UI. '
 'No Chinese/East Asian fantasy, palace roofs, cloud-scroll ornament, calligraphy, jade pendants or eastern dragons. No blown-out whites or particle noise. ')
paths={}
for a in assets:
    group,key=a['group'],a['id']
    if group=='playing':
        a['engineSuit']=a['suit']
        a['suit']=key.split('_')[1]
        subject=f"One {roles[a['rank']]} in {biomes[a['suit']]}. Show the ability '{a['name']}' through one clear action or central relic; use the exact mechanics below as visual cues, with a calm background."
        filename=a['suit']+'_'+{11:'J',12:'Q',13:'K',14:'A'}.get(a['rank'],str(a['rank']))
        prior=[f'assets/cards/{filename}.png']
    else:
        filename=key
        subject=concepts.get(key,f"One clearly readable Western continental relic or entity expressing '{a['name']}' and its exact ability below; choose an appropriate discovery biome, no decorative clutter.")
        if group=='enemy': subject=f"One {key.replace('_',' ')} encountered on the continental expedition. Make its silhouette and one central supernatural action express the actual ability below; Western dark-fantasy creature design with one appropriate biome and a quiet background."
        old_folder={'spn':'deities/illustrated','itm':'equipment/illustrated','hand':'hands/illustrated','chest':'packs','playing':'cards','enemy':'scene/enemies','voucher':'vouchers','back':'cards'}.get(group,'consumables')
        old_name='pack_'+key if group=='chest' else key
        prior=[f'assets/{old_folder}/{old_name}.png']
    a['concept']=subject
    a['file']=f'assets/cards/continental/{group}/{filename}.png'
    a['previous_paths']=prior
    a['redesigned_from_existing']=any((ROOT/p).exists() for p in prior)
    a['prompt']=base+family_style.get(group,'A clear central ability symbol or relic in the shared continental world.')+f" Identity: {a['name']}. Actual gameplay ability: {a['ability']}. Subject/concept: {subject}"
    a['status']='pending'
    (ROOT/a['file']).parent.mkdir(parents=True,exist_ok=True)
    paths[key]=a['file']
    if group=='playing': paths[filename]=a['file']
for alias,target in {'ed_foil':'edition_foil','ed_holo':'edition_holographic','ed_poly':'edition_polychrome'}.items():
    if alias in paths: paths[target]=paths[alias]
    elif target in paths: paths[alias]=paths[target]
paths['v_hand_size']=paths['hand_expansion']
manifest={'style':'Cinematic Dark-Fantasy Expedition','mode':'built-in image_gen','ratio':'2:3','reference':'User-provided giant continent','assets':assets}
(ROOT/'docs/asset_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
(ROOT/'config/continental_asset_paths.lua').write_text('return {\n'+''.join(f'    ["{key}"] = "{path}",\n' for key,path in paths.items())+'}\n',encoding='utf-8')
(ROOT/'docs/CONTINENTAL_ASSET_PROMPTS.md').write_text('# Prompts and concepts\n\n'+ '\n\n'.join(f"## {a['group']} / {a['id']} — {a['name']}\n\nAbility: {a['ability']}\n\nConcept: {a['concept']}\n\nPrompt: {a['prompt']}\n\nOutput: `{a['file']}`\n\nSource: `{a['source']}`; previous: {', '.join(a['previous_paths'])}" for a in assets),encoding='utf-8')
print(f'Prepared {len(assets)} prompts and output paths')
