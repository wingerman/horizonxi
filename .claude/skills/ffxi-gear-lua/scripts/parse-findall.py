#!/usr/bin/env python3
"""Read a FindAll (Ashita v4 plugin by Thorny) inventory cache and list the character's equipment.

usage: parse-findall.py <Name_Id.bin> --items items.lua [--job BLU] [--md out.md] [--json out.json] [--gil]

The cache lives at Game\\config\\plugins\\findall\\cache\\<Name>_<Id>.bin and holds whatever the client has
received: Mog House containers are only as fresh as the last Mog House visit, and empty containers are
either empty or never loaded. Layout (FindAll InventoryCache.cpp, TryWriteFile):

    char Name[16]; uint32 Id;
    for container in 0..16 except 3 (Temporary): 81 x item_t
    uint8 KeyItems[4096]

item_t is Ashita's 44-byte record: uint16 Id, uint16 Index, uint32 Count, uint32 Flags, uint32 Price,
uint8 Extra[28]. Inventory index 0 with Id 0xFFFF is gil (Count). Names come from Windower's item resource
(https://raw.githubusercontent.com/Windower/Resources/master/resources_data/items.lua), whose `en` field is
the in-game short name that LuAshitacast and GearSwap match on ("Scp. Harness +1", "Jr.Msk.Chakram +2").

Container names are Ashita's enum names. A server's client may label wardrobes differently in game; the
items are right even when the label is not.
"""
import argparse
import json
import re
import struct
import sys
from pathlib import Path

CONTAINERS = ['Inventory', 'Safe', 'Storage', 'Temporary', 'Locker', 'Satchel', 'Sack', 'Case', 'Wardrobe',
              'Safe2', 'Wardrobe2', 'Wardrobe3', 'Wardrobe4', 'Wardrobe5', 'Wardrobe6', 'Wardrobe7', 'Wardrobe8']
WRITTEN = [i for i in range(len(CONTAINERS)) if CONTAINERS[i] != 'Temporary']
SLOTS = ['Main', 'Sub', 'Range', 'Ammo', 'Head', 'Body', 'Hands', 'Legs', 'Feet', 'Neck', 'Waist',
         'Ear1', 'Ear2', 'Ring1', 'Ring2', 'Back']
SLOT_ORDER = ['Main', 'Sub', 'Range', 'Ammo', 'Head', 'Neck', 'Ear', 'Body', 'Hands', 'Ring', 'Back', 'Waist',
              'Legs', 'Feet']
JOBS = ['NONE', 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN',
        'DRG', 'SMN', 'BLU', 'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN']
ITEM_T = struct.Struct('<HHIII28s')
assert ITEM_T.size == 44


def slot_label(mask):
    names = [SLOTS[i] for i in range(16) if mask & (1 << i)]
    if 'Ear1' in names:
        names = [n for n in names if n not in ('Ear1', 'Ear2')] + ['Ear']
    if 'Ring1' in names:
        names = [n for n in names if n not in ('Ring1', 'Ring2')] + ['Ring']
    return '/'.join(names)


def load_items(path):
    """Parse Windower items.lua into {id: {en, category, slots, level, jobs}} with a regex, no Lua needed."""
    items = {}
    pat = re.compile(r'^\s*\[(\d+)\] = \{(.*)\},?$')
    for line in Path(path).read_text(encoding='utf-8', errors='replace').splitlines():
        m = pat.match(line)
        if not m:
            continue
        body = m.group(2)
        d = {'id': int(m.group(1))}
        en = re.search(r'\ben="((?:[^"\\]|\\.)*)"', body)
        d['en'] = en.group(1).replace('\\"', '"') if en else f'item {d["id"]}'
        for key in ('category',):
            k = re.search(rf'\b{key}="([^"]*)"', body)
            d[key] = k.group(1) if k else ''
        for key in ('slots', 'level', 'jobs'):
            k = re.search(rf'\b{key}=(\d+)', body)
            d[key] = int(k.group(1)) if k else 0
        items[d['id']] = d
    return items


def parse_bin(path):
    data = Path(path).read_bytes()
    expected = 16 + 4 + len(WRITTEN) * 81 * ITEM_T.size + 4096
    if len(data) != expected:
        sys.exit(f'{path}: {len(data)} bytes, expected {expected}; not a FindAll cache or the format changed')
    name = data[:16].split(b'\0', 1)[0].decode('ascii', 'replace')
    char_id = struct.unpack_from('<I', data, 16)[0]
    off = 20
    containers = {}
    gil = 0
    for cid in WRITTEN:
        rows = []
        for idx in range(81):
            item_id, index, count, flags, price, extra = ITEM_T.unpack_from(data, off)
            off += ITEM_T.size
            if item_id == 0 or count == 0:
                continue
            if cid == 0 and idx == 0 and item_id == 0xFFFF:
                gil = count
                continue
            rows.append({'id': item_id, 'index': idx, 'count': count, 'flags': flags})
        containers[CONTAINERS[cid]] = rows
    key_items = sum(bin(b).count('1') for b in data[off:off + 4096])
    return name, char_id, containers, gil, key_items


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('bin')
    ap.add_argument('--items', required=True, help='Windower resources_data/items.lua')
    ap.add_argument('--job', help='three-letter job; adds a column saying whether the item lists that job')
    ap.add_argument('--md', help='write the equipment table as markdown here')
    ap.add_argument('--json', help='write every item (equipment or not) as JSON here')
    ap.add_argument('--gil', action='store_true', help='print gil (left out by default; it is personal)')
    a = ap.parse_args()

    items = load_items(a.items)
    name, char_id, containers, gil, key_items = parse_bin(a.bin)
    job_bit = (1 << JOBS.index(a.job.upper())) if a.job else 0

    print(f'{name} ({char_id}); key items set: {key_items}' + (f'; gil {gil:,}' if a.gil else ''))
    print('items per container: ' + ', '.join(f'{c} {len(r)}' for c, r in containers.items() if r))
    empty = [c for c, r in containers.items() if not r]
    if empty:
        print('empty in the cache: ' + ', '.join(empty) + ' (empty, or never loaded by the client)')

    rows, unknown = [], 0
    for cname, crows in containers.items():
        for r in crows:
            info = items.get(r['id'])
            if info is None:
                unknown += 1
                info = {'en': f'unknown id {r["id"]}', 'category': '', 'slots': 0, 'level': 0, 'jobs': 0}
            r.update({'name': info['en'], 'container': cname, 'category': info['category'],
                      'slots': info['slots'], 'level': info['level'], 'jobs': info['jobs']})
            rows.append(r)
    if unknown:
        print(f'{unknown} item ids not in items.lua (resource out of date, or server-custom items)')

    equipment = [r for r in rows if r['slots']]
    def sort_key(r):
        lab = slot_label(r['slots']).split('/')[0]
        return (SLOT_ORDER.index(lab) if lab in SLOT_ORDER else 99, -r['level'], r['name'])
    equipment.sort(key=sort_key)
    print(f'equipment: {len(equipment)} items')

    if a.md:
        hdr = ['Slot', 'Item', 'Lv'] + ([a.job.upper()] if a.job else []) + ['Where']
        lines = ['| ' + ' | '.join(hdr) + ' |', '|' + '---|' * len(hdr)]
        for r in equipment:
            cells = [slot_label(r['slots']), r['name'], str(r['level'])]
            if a.job:
                cells.append('yes' if r['jobs'] & job_bit else '')
            cells.append(r['container'])
            lines.append('| ' + ' | '.join(cells) + ' |')
        Path(a.md).write_text('\n'.join(lines) + '\n')
        print(f'wrote {a.md}')
    if a.json:
        Path(a.json).write_text(json.dumps({'name': name, 'id': char_id, 'items': rows}, indent=1))
        print(f'wrote {a.json}')


if __name__ == '__main__':
    main()
