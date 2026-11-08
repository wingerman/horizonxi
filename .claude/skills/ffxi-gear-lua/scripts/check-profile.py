#!/usr/bin/env python3
"""Structural check for LuAshitacast profiles. No Lua interpreter needed.

usage: check-profile.py <profile.lua> [more.lua ...]      exit 1 if any file has an error

Errors (the profile will misbehave or fail to load):
  - unbalanced braces, parentheses, or block keywords (function/if/for/while vs end)
  - a reference like sets.Foo to a set that is not defined in the `local sets = {` block
  - a set that names Range or Ammo but not the other, in a profile that uses both slots somewhere,
    or a Range/Ammo pair the server will not allow together (see references/ffxi-invariants.md)
  - a slot name LuAshitacast does not know
  - a slot assigned twice in one set (the second wins silently; usually Ear1/Ear1 meant Ear1/Ear2)
Warnings (legal, but probably not what was meant):
  - Slot = ''   does nothing; use 'remove' to clear a slot
  - a list in a slot outside a *_Priority set is ignored by the addon
  - a Range or Ammo item the pairing table does not know, in a set that names both

The check is regex based: it needs one `local sets = {` block whose top-level entries are the sets.
Indentation does not matter. Profiles without such a block get the balance checks only.
"""
import re
import sys
from pathlib import Path

SLOT_NAMES = {s.lower() for s in ['Main', 'Sub', 'Range', 'Ammo', 'Head', 'Neck', 'Ear1', 'Ear2', 'Body',
                                   'Hands', 'Ring1', 'Ring2', 'Back', 'Waist', 'Legs', 'Feet',
                                   'Ear', 'Ring', 'Ears', 'Rings', 'Lear', 'Rear', 'Lring', 'Rring']}
SET_META = {'NoWrite', 'Priority'}

# Skill types from the server's item_weapon table. Stat ammo has skill 0 and pairs with nothing.
RANGED_KIND = {
    'happy egg': 'stat', 'fortune egg': 'stat', 'phtm. tathlum': 'stat', 'morion tathlum': 'stat',
    'white tathlum': 'stat', 'hedgehog bomb': 'stat', 'bomb core': 'stat', "fenrir's stone": 'stat',
    'tiphia sting': 'stat', 'bibiki seashell': 'stat', 'olibanum sachet': 'stat', 'fire bomblet': 'stat',
    'jr.msk.chakram +2': 'throw', 'jr.msk.chakram +1': 'throw', 'jr.msk.chakram': 'throw',
    "junior musketeer's chakram +2": 'throw', 'ungur boomerang': 'throw', 'rising sun': 'throw',
    'boomerang': 'throw', 'chakram': 'throw', 'smart grenade': 'throw',
    'rapid bow': 'bow', 'lightning bow': 'bow', 'hamayumi': 'bow',
    "thug's zamburak": 'xbow', 'zamburak': 'xbow', 'velocity bow': 'xbow', "othinus' bow": 'xbow',
    'donderbuss': 'gun',
    'gjallarhorn': 'instrument', "nursemaid's harp": 'instrument',
    'crossbow bolt': 'bolt', 'acid bolt': 'bolt', 'sleep bolt': 'bolt', 'bloody bolt': 'bolt',
    'holy bolt': 'bolt', 'blind bolt': 'bolt', 'venom bolt': 'bolt',
    'antlion arrow': 'arrow', 'nokizaru shuriken': 'shuriken',
}
LEGAL_PAIR = {'bow': 'arrow', 'xbow': 'bolt', 'gun': 'bullet', 'throw': 'shuriken'}
KEYWORDS = {'', 'remove', 'displaced', 'ignore'}


def strip_comments(src):
    src = re.sub(r'--\[\[.*?\]\]', '', src, flags=re.S)
    return re.sub(r'--[^\n]*', '', src)


def strip_strings(src):
    src = re.sub(r"'(?:\\.|[^'\\\n])*'", "''", src)
    return re.sub(r'"(?:\\.|[^"\\\n])*"', '""', src)


def unquote(v):
    m = re.match(r"""^(?:'((?:\\.|[^'\\])*)'|"((?:\\.|[^"\\])*)")$""", v.strip())
    if not m:
        return None
    return (m.group(1) if m.group(1) is not None else m.group(2)).replace("\\'", "'").replace('\\"', '"')


def parse_sets_block(nocomment):
    """Return {setName: [(slot, rawValue), ...]} from the `local sets = {` block, by brace depth."""
    m = re.search(r'^local sets\s*=\s*\{', nocomment, re.M)
    if not m:
        return None
    sets, depth, cur = {}, 0, None
    for line in nocomment[m.end():].split('\n'):
        bare = strip_strings(line)
        if depth == 0:
            if re.match(r'^\s*\}', bare):
                break
            # match on the unstripped line: ['Idle'] = { is a common header form and stripping would blank the name
            hm = re.match(r'^\s*\[?[\'"]?([A-Za-z_]\w*)[\'"]?\]?\s*=\s*\{', line)
            if hm:
                cur = hm.group(1)
                sets[cur] = []
                rest = line[hm.end() - 0:]  # anything after the opening brace on the same line
                for sm in re.finditer(r'([A-Za-z_]\w*)\s*=\s*((?:\'(?:\\.|[^\'\\])*\')|(?:"(?:\\.|[^"\\])*")|\{[^}]*\}|[^,}]+)', rest):
                    sets[cur].append((sm.group(1), sm.group(2).strip()))
        elif depth == 1 and cur is not None:
            sm = re.match(r'^\s*([A-Za-z_]\w*)\s*=\s*(.+?),?\s*$', line)
            if sm:
                sets[cur].append((sm.group(1), sm.group(2).strip()))
        depth += bare.count('{') - bare.count('}')
        if depth < 0:
            break
    return sets


def check(path):
    errors, warnings = [], []
    src = Path(path).read_text(encoding='utf-8', errors='replace')
    nocomment = strip_comments(src)
    code = strip_strings(nocomment)

    for a, b, what in [('{', '}', 'braces'), ('(', ')', 'parentheses'), ('[', ']', 'brackets')]:
        if code.count(a) != code.count(b):
            errors.append(f'unbalanced {what}: {code.count(a)} {a} vs {code.count(b)} {b}')
    opens = len(re.findall(r'\b(?:function|if|for|while)\b', code))
    ends = len(re.findall(r'\bend\b', code))
    if opens != ends:
        errors.append(f'unbalanced blocks: {opens} function/if/for/while vs {ends} end')

    sets = parse_sets_block(nocomment)
    if sets is None:
        warnings.append('no `local sets = {` block found; set checks skipped')
        return errors, warnings
    if not sets:
        warnings.append('sets block found but no sets parsed; set checks skipped')
        return errors, warnings

    for r in sorted(set(re.findall(r'\bsets\.([A-Za-z_]\w*)', code)) - set(sets)):
        errors.append(f'sets.{r} is used but not defined')
    for prefix in set(re.findall(r"sets\[\s*'([A-Za-z_]+_)'\s*\.\.", nocomment)):
        if not any(s.startswith(prefix) for s in sets):
            errors.append(f"sets['{prefix}' .. x] is used but no set starts with {prefix}")

    def named(slot_values, *slots):
        for s, v in slot_values:
            if s.lower() in slots:
                u = unquote(v)
                return v if u is None else u
        return None

    uses_range = any(named(b, 'range') not in (None, *KEYWORDS) for b in sets.values())
    uses_ammo = any(named(b, 'ammo') not in (None, *KEYWORDS) for b in sets.values())

    for name, body in sets.items():
        seen = set()
        for slot, value in body:
            if slot.lower() not in SLOT_NAMES and slot not in SET_META:
                errors.append(f'{name}.{slot}: not a slot name')
            if slot in seen:
                errors.append(f'{name}: {slot} assigned twice (second wins; Ear1/Ear2 or Ring1/Ring2 mix-up?)')
            seen.add(slot)
            if unquote(value) == '':
                warnings.append(f"{name}.{slot} = '' does nothing; use 'remove' to clear the slot")
            if re.match(r'^T?\{', value) and 'Name' not in value and not name.endswith('_Priority'):
                warnings.append(f'{name}.{slot} is a list; the addon ignores lists outside *_Priority sets')

        rng, ammo = named(body, 'range'), named(body, 'ammo')
        if rng is not None and ammo is None and uses_ammo:
            errors.append(f"{name}: names Range but not Ammo while other sets equip Ammo; add Ammo = 'remove' "
                          f'(the server empties one slot when skill types differ and the addon re-equips it: flicker)')
        elif ammo is not None and rng is None and uses_range:
            errors.append(f"{name}: names Ammo but not Range while other sets equip Range; add Range = 'remove' "
                          f'(the server empties one slot when skill types differ and the addon re-equips it: flicker)')
        elif rng is not None and ammo is not None:
            rk = None if rng in KEYWORDS else RANGED_KIND.get(rng.lower(), 'unknown')
            ak = None if ammo in KEYWORDS else RANGED_KIND.get(ammo.lower(), 'unknown')
            for lbl, k, v in (('Range', rk, rng), ('Ammo', ak, ammo)):
                if k == 'unknown' and rk is not None and ak is not None:
                    warnings.append(f'{name}.{lbl} "{v}" is not in the pairing table; add it to RANGED_KIND')
            if rk and ak and 'unknown' not in (rk, ak) and LEGAL_PAIR.get(rk) != ak:
                errors.append(f'{name}: {rng} ({rk}) and {ammo} ({ak}) cannot be worn together')
    return errors, warnings


def main(argv):
    if not argv:
        print(__doc__)
        return 2
    bad = 0
    for p in argv:
        errors, warnings = check(p)
        print(f"{'FAIL' if errors else 'ok  '}  {p}  ({len(errors)} errors, {len(warnings)} warnings)")
        for e in errors:
            print(f'  error    {e}')
        for w in warnings:
            print(f'  warning  {w}')
        bad += bool(errors)
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
